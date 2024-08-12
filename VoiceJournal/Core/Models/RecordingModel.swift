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
    
    private var viewContext: NSManagedObjectContext
    private var audioEngine: AVAudioEngine
    private var audioRecorder: AVAudioRecorder?
    private var audioInputNode: AVAudioInputNode
    private var audioFileURL: URL?
    
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
    
    // Request Mic Permission
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission() { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // Request speech recognition
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
    
    // Configure Audio Session and Recorder
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
    
    // Start Recording
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
    
    // Stop Recording
    func stopRecording() {
        audioEngine.stop()
        isRecording = false
        self.audioRecorder?.stop()
        self.audioRecorder = nil
        print("Audio recording stopped.")
    }
    
    // MARK: - Process Audio
    
    // Finished Recording
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag, let audioFileURL = self.audioFileURL {
            print("Audio recorder stopped successfully")
            // Save recording data first without transcription
            saveRecordingData(audioURL: audioFileURL)
            
            // Start transcription in background
            DispatchQueue.global(qos: .background).async {
                self.transcribeAudio(url: audioFileURL) { transcription in
                    DispatchQueue.main.async {
                        if let transcription = transcription {
                            self.processEmotions(audioFileURL: audioFileURL, transcription: transcription)
                        }
                    }
                }
            }
        } else {
            print("Recording failed")
        }
    }
    
    // Transcribe Audio
    private func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Transcription error: \(error.localizedDescription)")
                completion(nil)
            } else if let result = result {
                if result.isFinal {
                    completion(result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    // MARK: - Colors and Emotion Detection

    // Process Emotion, Color, and Update Journal
    private func processEmotions(audioFileURL: URL, transcription: String) {
        let emotions = detectEmotion(for: transcription)
        let emotionColors = colorForEmotion(emotions)
        updateJournal(audioFileURL: audioFileURL, transcription: transcription, emotions: emotions, colors: emotionColors)
    }
    
    // Emotion detection
    func detectEmotion(for text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        guard let sentimentScore = sentiment?.rawValue, let score = Double(sentimentScore) else {
            return ["neutral"]
        }
        
        if score > 0.75 {
            return ["joy", "happiness"]
        } else if score > 0.5 {
            return ["contentment", "pleasure"]
        } else if score > 0.25 {
            return ["calm", "satisfaction"]
        } else if score < -0.75 {
            return ["anger", "rage"]
        } else if score < -0.5 {
            return ["sadness", "grief"]
        } else if score < -0.25 {
            return ["disappointment", "frustration"]
        } else {
            return ["neutral"]
        }
    }
    
    // Assign colors to emotions
    func colorForEmotion(_ emotions: [String]) -> [Color] {
        var emotionColors: [Color] = []

        for emotion in emotions {
            switch emotion {
            case "joy", "happiness":
                emotionColors.append(Color.yellow)
            case "contentment", "pleasure":
                emotionColors.append(Color.green)
            case "calm", "satisfaction":
                emotionColors.append(Color.blue)
            case "anger", "rage":
                emotionColors.append(Color.red)
            case "sadness", "grief":
                emotionColors.append(Color.gray)
            case "disappointment", "frustration":
                emotionColors.append(Color.orange)
            default:
                emotionColors.append(Color.gray)
            }
        }

        return emotionColors
    }

    
    // MARK: - Save and Update Journal
    
    // Save Recording to Core Data
    func saveRecordingData(audioURL: URL, transcription: String? = nil) {
        let newJournal = Journal(context: viewContext)
        newJournal.audioFileName = audioURL.lastPathComponent
        newJournal.date = Date()
        newJournal.audioTranscription = transcription
        
        // Attempt to retrieve and save the duration
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
    
    // Update Journal with Transcription, Emotions, Colors
    private func updateJournal(audioFileURL: URL, transcription: String, emotions: [String], colors: [Color]) {
        let fetchRequest: NSFetchRequest<Journal> = Journal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "audioFileName == %@", audioFileURL.lastPathComponent)

        do {
            let journals = try viewContext.fetch(fetchRequest)
            if let journal = journals.first {
                journal.audioTranscription = transcription
                journal.emotions = emotions as NSObject
                journal.emotionColors = colors as NSObject

                try viewContext.save()
                print("Journal updated with transcription, emotions, and colors.")
            } else {
                print("No journal found for audio file name \(audioFileURL.lastPathComponent)")
            }
        } catch {
            print("Failed to update journal: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helpers
    
    // AV Audio Recorder Error
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recording error: \(error.localizedDescription)")
        }
    }
    
    // Method to get unique audio file URL
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

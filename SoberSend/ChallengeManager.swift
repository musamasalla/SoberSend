import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
class ChallengeManager {
    var isRecording = false
    var speechScore: Double = 0.0
    var recognizedText = ""
    var isAuthorizedForSpeech: Bool = false
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        checkSpeechAuthorization()
    }
    
    func checkSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.isAuthorizedForSpeech = status == .authorized
            }
        }
    }
    
    func startRecording(targetPhrase: String) throws {
        // Reset state
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        
        recognizedText = ""
        speechScore = 0.0
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { throw ChallengeError.speechRequestFailed }
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            Task { @MainActor in
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    self.speechScore = self.calculateSimilarity(between: targetPhrase, and: self.recognizedText)
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }
        
        try audioEngine.start()
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        isRecording = false
    }
    
    // Simple similarity check implementation.
    // In production, an algorithm like Levenshtein distance would be used.
    private func calculateSimilarity(between target: String, and output: String) -> Double {
        let tWords = target.lowercased().split(separator: " ")
        let oWords = output.lowercased().split(separator: " ")
        
        if oWords.isEmpty { return 0.0 }
        
        var matches = 0.0
        for word in tWords {
            if output.lowercased().contains(word) {
                matches += 1.0
            }
        }
        
        return matches / Double(tWords.count)
    }
}

enum ChallengeError: Error, LocalizedError {
    case speechRequestFailed
    
    var errorDescription: String? {
        switch self {
        case .speechRequestFailed:
            return "Unable to create speech recognition request."
        }
    }
}

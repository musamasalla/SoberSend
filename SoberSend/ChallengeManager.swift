import Foundation
import Speech
import AVFoundation

/// Manages speech recognition for the speech challenge.
/// Provides live transcription and accuracy scoring.
@MainActor
@Observable
class ChallengeManager {
    var isRecording = false
    /// The accuracy score (0.0–1.0) of the last recognized speech.
    var speechScore: Double = 0.0
    /// The raw text provided by the speech recognizer.
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
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
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
        
        // Deactivate audio session only if we were recording
        if isRecording {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                // Audio session may already be inactive; ignore
            }
        }
        isRecording = false
    }
    
    // MARK: - Accuracy scoring
    
    /// Calculates a similarity score between the original target phrase and
    /// the user's spoken input.
    ///
    /// The algorithm normalises both strings (removes punctuation,
    /// converts to lowercase, trims) then uses Levenshtein distance to
    /// produce a score between 0.0 and 1.0.
    private func calculateSimilarity(between target: String, and output: String) -> Double {
        let normalisedTarget = SpeechChallengeScorer.normalise(target)
        let normalisedOutput = SpeechChallengeScorer.normalise(output)
        
        guard !normalisedOutput.isEmpty else { return 0.0 }
        
        let distance = SpeechChallengeScorer.levenshteinDistance(
            between: normalisedTarget,
            and: normalisedOutput
        )
        
        let maxLength = max(normalisedTarget.count, normalisedOutput.count)
        guard maxLength > 0 else { return 0.0 }
        
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        return max(0.0, min(1.0, similarity))
    }
}

/// Utility for normalising and scoring speech challenge phrases.
struct SpeechChallengeScorer {
    
    /// Returns a lowercased, punctuation-stripped, space-normalised string.
    static func normalise(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        // Remove punctuation but preserve spaces
        let filtered = lowercased.unicodeScalars
            .filter { CharacterSet.letters.contains($0) || CharacterSet.whitespacesAndNewlines.contains($0) }
            .map { String($0) }
            .joined()
        // Collapse multiple spaces into single spaces
        return filtered
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    /// Computes the Levenshtein distance between two strings using a
    /// space-optimised dynamic programming approach.
    ///
    /// The result represents the minimum number of single-character
    /// insertions, deletions, and substitutions required to transform
    /// `a` into `b`.
    static func levenshteinDistance(between a: String, and b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let (m, n) = (aChars.count, bChars.count)
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        // Space-optimised: keep only the previous and current rows
        var previous = Array(0...n)
        var current = Array(repeating: 0, count: n + 1)
        
        for i in (1...m) {
            current[0] = i
            for j in (1...n) {
                let cost: Int = (aChars[i - 1] == bChars[j - 1]) ? 0 : 1
                current[j] = Swift.min(
                    previous[j] + 1,        // Deletion
                    current[j - 1] + 1,      // Insertion
                    previous[j - 1] + cost   // Substitution / match
                )
            }
            swap(&previous, &current)
        }
        
        return previous[n]
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

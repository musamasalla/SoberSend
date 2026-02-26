import Foundation
import SwiftData

@Model
final class ChallengeAttempt {
    var contactOrApp: String
    var timestamp: Date
    var passed: Bool
    var challengeTypeRawValue: String
    var attemptNumber: Int
    var unlockGranted: Bool

    init(contactOrApp: String, timestamp: Date = Date(), passed: Bool, challengeType: ChallengeType, attemptNumber: Int, unlockGranted: Bool) {
        self.contactOrApp = contactOrApp
        self.timestamp = timestamp
        self.passed = passed
        self.challengeTypeRawValue = challengeType.rawValue
        self.attemptNumber = attemptNumber
        self.unlockGranted = unlockGranted
    }

    var challengeType: ChallengeType {
        get { ChallengeType(rawValue: challengeTypeRawValue) ?? .math }
        set { challengeTypeRawValue = newValue.rawValue }
    }
}

enum ChallengeType: String, Codable, CaseIterable {
    case math
    case memory
    case speech
    case combined
}

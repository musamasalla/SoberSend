import Foundation
import SwiftData

@Model
final class LockedContact {
    var contactID: String
    var displayName: String
    var difficultyRawValue: String
    var soberNote: String?
    var lockScheduleStart: Date
    var lockScheduleEnd: Date
    var isActive: Bool
    var phoneNumber: String?

    init(contactID: String, displayName: String, difficulty: ChallengeDifficulty = .medium, soberNote: String? = nil, lockScheduleStart: Date = Date(), lockScheduleEnd: Date = Date(), isActive: Bool = true, phoneNumber: String? = nil) {
        self.contactID = contactID
        self.displayName = displayName
        self.difficultyRawValue = difficulty.rawValue
        self.soberNote = soberNote
        self.lockScheduleStart = lockScheduleStart
        self.lockScheduleEnd = lockScheduleEnd
        self.isActive = isActive
        self.phoneNumber = phoneNumber
    }

    var difficulty: ChallengeDifficulty {
        get { ChallengeDifficulty(rawValue: difficultyRawValue) ?? .medium }
        set { difficultyRawValue = newValue.rawValue }
    }
}

enum ChallengeDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard
    case expert
}

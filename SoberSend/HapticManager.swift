import UIKit

@MainActor
final class HapticManager: Sendable {
    static let shared = HapticManager()

    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let dragGenerator = UIImpactFeedbackGenerator(style: .light)
    private let alignmentGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepareAll()
    }

    private func prepareAll() {
        notificationGenerator.prepare()
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactRigid.prepare()
        impactSoft.prepare()
        selectionGenerator.prepare()
        dragGenerator.prepare()
        alignmentGenerator.prepare()
    }

    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
    }

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()
        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        case .rigid:
            impactRigid.impactOccurred()
            impactRigid.prepare()
        case .soft:
            impactSoft.impactOccurred()
            impactSoft.prepare()
        default:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        }
    }

    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func alignment() {
        alignmentGenerator.selectionChanged()
        alignmentGenerator.prepare()
    }

    func dragStart() {
        dragGenerator.impactOccurred(intensity: 0.5)
        dragGenerator.prepare()
    }

    func success() {
        notification(type: .success)
    }

    func error() {
        notification(type: .error)
    }

    func warning() {
        notification(type: .warning)
    }

    func lightTap() {
        impact(style: .light)
    }

    func mediumTap() {
        impact(style: .medium)
    }

    func heavyTap() {
        impact(style: .heavy)
    }

    func rigidTap() {
        impact(style: .rigid)
    }

    func softTap() {
        impact(style: .soft)
    }
}
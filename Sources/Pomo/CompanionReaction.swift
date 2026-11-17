import Foundation

/// Transient presentation state. Never changes saved progression or timer state.
struct CompanionReaction {
    let startedAt: Date
    let grew: Bool
    var duration: TimeInterval { grew ? 4.6 : 2.6 }
    func phase(at date: Date) -> Phase {
        let elapsed = date.timeIntervalSince(startedAt)
        guard elapsed >= 0 && elapsed < duration else { return .idle }
        if elapsed < 1.2 { return .eating }
        return grew ? .growing : .happy
    }
    enum Phase { case idle, eating, happy, growing }
}

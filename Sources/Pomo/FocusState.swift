import Foundation

enum Companion: String, Codable, CaseIterable, Identifiable {
    case pomo, mori, pip, sprout, nook, ember
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var detail: String {
        switch self {
        case .pomo: "A little focus friend with a big heart."
        case .mori: "A quiet woodland soul."
        case .pip: "Small wings. So much potential."
        case .sprout: "Good things grow a little at a time."
        case .nook: "Every day, a little more at home."
        case .ember: "Keep your little spark glowing."
        }
    }
}

enum SessionPhase: String, Codable {
    case focus, shortBreak, longBreak
    var title: String {
        switch self { case .focus: "Focus time"; case .shortBreak: "Take a breath"; case .longBreak: "A well-earned rest" }
    }
}

struct FocusState: Codable {
    var version = 1
    var companion: Companion?
    var nickname = ""
    var focusMinutes = 25
    var breakMinutes = 5
    var phase: SessionPhase = .focus
    var remaining: TimeInterval = 25 * 60
    var deadline: Date?
    var completedSessions = 0
    var focusedMinutes = 0
    var treats = 0
    var fedTreats = 0
    // Optional fields keep existing version-one saves readable.
    var nextFocusMinutes: Int?
    var customFocusPresets: [Int]?
    var rewardMinutesRemainder: Int?

    static let minutesPerTreat = 5
    var minutesTowardNextTreat: Int { rewardMinutesRemainder ?? 0 }
    func treatsForFocus(minutes: Int) -> Int {
        (minutesTowardNextTreat + minutes) / Self.minutesPerTreat
    }

    static let defaultFocusPresets = [10, 15, 25, 30, 45, 60]
    var focusPresets: [Int] { customFocusPresets ?? Self.defaultFocusPresets }
    var selectedFocusMinutes: Int { nextFocusMinutes ?? focusMinutes }

    @discardableResult mutating func selectFocusMinutes(_ minutes: Int) -> Bool {
        guard (1...180).contains(minutes) else { return false }
        if phase != .focus || (deadline == nil && remaining == duration) {
            focusMinutes = minutes
            nextFocusMinutes = nil
            if phase == .focus { remaining = duration }
        } else {
            nextFocusMinutes = minutes == focusMinutes ? nil : minutes
        }
        return true
    }

    @discardableResult mutating func setFocusPresets(_ minutes: [Int]) -> Bool {
        guard !minutes.isEmpty, minutes.count <= 8,
              minutes.allSatisfy({ (1...180).contains($0) }), Set(minutes).count == minutes.count else { return false }
        customFocusPresets = minutes.sorted()
        return true
    }

    private mutating func applyNextDuration() {
        if let nextFocusMinutes {
            focusMinutes = nextFocusMinutes
            self.nextFocusMinutes = nil
        }
    }

    var level: Int { 1 + fedTreats / 4 }
    var displayName: String { nickname.isEmpty ? (companion?.title ?? "Your companion") : nickname }
    var duration: TimeInterval {
        TimeInterval((phase == .focus ? focusMinutes : phase == .shortBreak ? breakMinutes : 15) * 60)
    }

    mutating func changeCompanion(to companion: Companion) {
        self.companion = companion
    }

    mutating func start(at now: Date) {
        guard deadline == nil else { return }
        deadline = now.addingTimeInterval(remaining)
    }

    @discardableResult mutating func advance(to now: Date) -> Bool {
        guard let deadline else { return false }
        remaining = max(0, deadline.timeIntervalSince(now))
        guard remaining == 0 else { return false }
        self.deadline = nil
        if phase == .focus {
            completedSessions += 1
            focusedMinutes += focusMinutes
            let rewardMinutes = minutesTowardNextTreat + focusMinutes
            treats += rewardMinutes / Self.minutesPerTreat
            rewardMinutesRemainder = rewardMinutes % Self.minutesPerTreat
            applyNextDuration()
            phase = completedSessions.isMultiple(of: 4) ? .longBreak : .shortBreak
        } else {
            phase = .focus
        }
        remaining = duration
        return true
    }

    mutating func pause(at now: Date) {
        advance(to: now)
        deadline = nil
    }

    mutating func reset() {
        applyNextDuration()
        deadline = nil
        remaining = duration
    }

    @discardableResult mutating func feed() -> Bool {
        guard treats > 0 else { return false }
        treats -= 1
        fedTreats += 1
        return true
    }
}

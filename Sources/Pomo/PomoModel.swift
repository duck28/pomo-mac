import SwiftUI
import AppKit
import Combine

@MainActor final class PomoModel: ObservableObject {
    @Published private(set) var state: FocusState
    @Published var message = "A little focus. A little growth."
    @Published private(set) var reaction: CompanionReaction?
    @Published var storageError: String?
    private let saveURL: URL
    private var ticker: AnyCancellable?

    init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        saveURL = root.appendingPathComponent("Pomo/progress.json")
        do {
            if FileManager.default.fileExists(atPath: saveURL.path) {
                state = try JSONDecoder().decode(FocusState.self, from: Data(contentsOf: saveURL))
            } else {
                state = FocusState()
            }
        } catch {
            state = FocusState()
            storageError = "Your saved progress could not be read. The original file has been kept. \(error.localizedDescription)"
        }
        tick()
        ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func save() {
        guard storageError == nil else { return }
        do {
            try FileManager.default.createDirectory(at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(state).write(to: saveURL, options: .atomic)
        } catch {
            storageError = "Progress could not be saved. \(error.localizedDescription)"
        }
    }

    func adopt(_ companion: Companion, name: String, minutes: Int) {
        state.companion = companion
        state.nickname = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
        state.focusMinutes = minutes
        state.reset()
        message = "You and \(state.displayName). One session at a time."
        save()
    }

    func changeCompanion(to companion: Companion) {
        state.changeCompanion(to: companion)
        message = "Your journey continues with \(state.displayName)."
        save()
    }

    func renameCompanion(_ name: String) {
        state.nickname = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
        save()
    }

    func selectFocusMinutes(_ minutes: Int) {
        tick()
        guard state.selectFocusMinutes(minutes) else { return }
        save()
    }

    func setFocusPresets(_ minutes: [Int]) {
        guard state.setFocusPresets(minutes) else { return }
        save()
    }

    func toggle() {
        if state.deadline == nil { state.start(at: Date()) } else { state.pause(at: Date()) }
        save()
    }

    func reset() { state.reset(); save() }

    func tick() {
        if let reaction, Date().timeIntervalSince(reaction.startedAt) >= reaction.duration {
            self.reaction = nil
        }
        let wasFocus = state.phase == .focus
        let previousTreats = state.treats
        if state.advance(to: Date()) {
            let earned = state.treats - previousTreats
            if wasFocus {
                message = earned > 0
                    ? "You did it. \(earned) \(earned == 1 ? "treat" : "treats") for \(state.displayName)!"
                    : "Focus saved. \(FocusState.minutesPerTreat - state.minutesTowardNextTreat) more minutes to your next treat."
            } else {
                message = "Ready for another small step?"
            }
            NSSound(named: "Glass")?.play()
            save()
        }
    }

    func feed() {
        let previousLevel = state.level
        if state.feed() {
            let grew = state.level > previousLevel
            reaction = CompanionReaction(startedAt: Date(), grew: grew || (reaction?.grew ?? false))
            message = grew
                ? "\(state.displayName) grew to bond level \(state.level)!"
                : "\(state.displayName) loved that. Your bond is growing."
            save()
        }
    }

    var clock: String {
        let seconds = Int(ceil(state.remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

import SwiftUI

/// A window-style menu extra allows live SwiftUI artwork and custom controls.
struct CompanionPopover: View {
    @ObservedObject var model: PomoModel
    @State private var showingSettings = false
    @Environment(\.openWindow) private var openWindow
    private var companion: Companion { model.state.companion ?? .pomo }
    private var running: Bool { model.state.deadline != nil }

    var body: some View {
        Group {
            if showingSettings {
                VStack(spacing: 0) {
                    HStack {
                        Button { showingSettings = false } label: { Label("Back", systemImage: "chevron.left") }
                            .buttonStyle(PomoButtonStyle(accent: companion.color, emphasis: .quiet))
                        Spacer()
                        Text("Settings").font(.headline)
                    }.padding(.horizontal, 16).padding(.top, 12)
                    ScrollView { PomoSettingsView(model: model, contentWidth: 350) }
                }.frame(width: 350, height: 640)
            } else {
                companionPanel
            }
        }
    }

    private var companionPanel: some View {
        VStack(spacing: 16) {
            HStack {
                Label("pomo", systemImage: "leaf.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                if model.state.companion != nil {
                    Text("Bond \(model.state.level)")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(companion.color.opacity(0.12), in: Capsule())
                }
            }
            CompanionView(companion: companion, level: model.state.level,
                          resting: running && model.state.phase == .focus, reaction: model.reaction)
                .frame(width: 150, height: 140)
            if model.state.companion != nil {
                Text(model.state.displayName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                VStack(spacing: 5) {
                    Text(model.state.phase.title.uppercased())
                        .font(.system(size: 10, weight: .semibold)).tracking(2)
                        .foregroundStyle(.secondary)
                    Text(model.clock)
                        .font(.system(size: 42, weight: .light, design: .rounded)).monospacedDigit()
                        .accessibilityLabel("\(model.clock) remaining")
                }
                FocusTimeMenu(model: model)
                HStack(spacing: 10) {
                    Button { model.toggle() } label: {
                        Label(running ? "Pause" : "Start", systemImage: running ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PomoButtonStyle(accent: companion.color, emphasis: .primary))
                    Button { model.feed() } label: {
                        Label("Feed · \(model.state.treats)", systemImage: "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(model.state.treats == 0)
                }
                .buttonStyle(PomoButtonStyle(accent: companion.color))
                Text(model.message)
                    .font(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Your little friend is waiting.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Text("Choose a companion to begin your first focus session.")
                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Divider().overlay(companion.color.opacity(0.12))
            VStack(spacing: 4) {
                Button { showingSettings = true } label: {
                    HStack {
                        Label("Settings", systemImage: "gearshape")
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }
                }
                .buttonStyle(PomoButtonStyle(accent: companion.color))
                HStack {
                    Button {
                        openWindow(id: "main")
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    } label: {
                        Label(model.state.companion == nil ? "Get started" : "Open Pomo", systemImage: "arrow.up.forward.square")
                    }
                    Spacer(minLength: 0)
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                }.buttonStyle(PomoButtonStyle(accent: companion.color, emphasis: .quiet))
            }
        }
        .padding(22).frame(width: 310)
        .background {
            LinearGradient(colors: [companion.color.opacity(0.10), Color(nsColor: .windowBackgroundColor)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

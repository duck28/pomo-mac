import SwiftUI

@main struct PomoApp: App {
    @NSApplicationDelegateAdaptor(PomoAppDelegate.self) private var delegate
    @StateObject private var model = PomoModel()
    var body: some Scene {
        Window("Pomo", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 660, minHeight: 720)
        }
        .defaultSize(width: 720, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Focus") {
                Button(model.state.deadline == nil ? "Start timer" : "Pause timer") { model.toggle() }
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                    .disabled(model.state.companion == nil)
            }
        }
        Settings { ScrollView { PomoSettingsView(model: model) }.frame(height: 700) }
        MenuBarExtra {
            CompanionPopover(model: model)
        } label: {
            Label(model.state.deadline == nil ? "Pomo" : model.clock, systemImage: "leaf")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct OpenWindowButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Show Pomo") { openWindow(id: "main"); NSApplication.shared.activate(ignoringOtherApps: true) }
    }
}

struct ContentView: View {
    @ObservedObject var model: PomoModel
    @State private var confirmReset = false
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            if model.state.companion == nil { OnboardingView(model: model) }
            else { dashboard }
        }
        .alert("Progress needs attention", isPresented: Binding(get: { model.storageError != nil }, set: { _ in })) {
            Button("Quit and keep saved file") { NSApplication.shared.terminate(nil) }
        } message: { Text(model.storageError ?? "") }
        .confirmationDialog("Restart this timer? Your unfinished session will not earn a treat.", isPresented: $confirmReset) {
            Button("Restart timer", role: .destructive) { model.reset() }
        }
    }

    private var dashboard: some View {
        VStack(spacing: 10) {
            HStack {
                Label("pomo", systemImage: "leaf.fill").font(.system(size: 19, weight: .semibold, design: .rounded))
                Spacer()
                Text("ONE SMALL STEP AT A TIME").font(.system(size: 10, weight: .medium)).tracking(2).foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)
            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    Capsule().fill(index < model.state.completedSessions % 4 ? accent : accent.opacity(0.16))
                        .frame(width: 25, height: 5)
                }
            }
            Text(model.state.phase.title.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(3).foregroundStyle(.secondary)
            Text(model.clock).font(.system(size: 68, weight: .light, design: .rounded)).monospacedDigit()
                .accessibilityLabel("\(model.clock) remaining")
            FocusTimeMenu(model: model)
                .fixedSize(horizontal: true, vertical: false)
            CompanionView(companion: model.state.companion ?? .pomo, level: model.state.level, resting: model.state.deadline != nil && model.state.phase == .focus, reaction: model.reaction)
                .frame(width: 180, height: 150)
            VStack(spacing: 6) {
                Text(model.state.displayName).font(.system(size: 23, weight: .semibold, design: .rounded))
                Text("Bond level \(model.state.level) · \(4 - model.state.fedTreats % 4) treats to grow").font(.callout).foregroundStyle(.secondary)
            }
            Text(model.message).font(.callout).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button { model.toggle() } label: {
                    Label(model.state.deadline == nil ? "Start \(model.state.phase == .focus ? "focus" : "break")" : "Pause", systemImage: model.state.deadline == nil ? "play.fill" : "pause.fill")
                        .frame(width: 130)
                }
                .buttonStyle(PomoButtonStyle(accent: accent, emphasis: .primary))
                Button { confirmReset = true } label: { Image(systemName: "arrow.counterclockwise") }
                    .buttonStyle(PomoButtonStyle(accent: accent, emphasis: .quiet)).help("Restart timer").accessibilityLabel("Restart timer")
                Button { model.feed() } label: { Label("Feed · \(model.state.treats)", systemImage: "heart.fill") }
                    .buttonStyle(PomoButtonStyle(accent: accent)).disabled(model.state.treats == 0)
            }
            Spacer(minLength: 0)
            HStack {
                stat("\(model.state.completedSessions)", "sessions finished")
                Spacer()
                stat("\(model.state.focusedMinutes)", "minutes of focus")
                Spacer()
                stat("\(model.state.fedTreats)", "little moments shared")
            }
            .padding(20).background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18))
            HStack {
                Spacer()
                SettingsLink { Label("Settings", systemImage: "gearshape") }
                    .buttonStyle(PomoButtonStyle(accent: accent, emphasis: .quiet))
            }
        }.padding(24)
    }
    private var accent: Color { (model.state.companion ?? .pomo).color }
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 21, weight: .medium, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct OnboardingView: View {
    @ObservedObject var model: PomoModel
    @State private var selected: Companion = .pomo
    @State private var nickname = ""
    @State private var minutes = 25
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("A little focus. A little friend.").font(.system(size: 31, weight: .semibold, design: .rounded))
                Text("Choose your companion. Grow together, one session at a time.")
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(Companion.allCases) { companion in
                        Button { selected = companion } label: {
                            VStack(spacing: 4) {
                                CompanionView(companion: companion).frame(height: 115)
                                HStack(spacing: 5) {
                                    Text(companion.title).font(.system(size: 17, weight: .semibold, design: .rounded))
                                    if selected == companion { Image(systemName: "checkmark.circle.fill").foregroundStyle(companion.color) }
                                }
                                Text(companion.detail).font(.caption).foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center).frame(height: 34)
                            }
                            .frame(maxWidth: .infinity).padding(12)
                            .background(companion.color.opacity(selected == companion ? 0.13 : 0.045), in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(selected == companion ? companion.color : .clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(companion.title). \(companion.detail)")
                        .accessibilityAddTraits(selected == companion ? [.isSelected] : [])
                    }
                }
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Give them a name").font(.callout.weight(.medium))
                        TextField(selected.title, text: $nickname)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 14).frame(height: 44)
                            .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.12)))
                            .accessibilityLabel("Companion name")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your focus rhythm").font(.callout.weight(.medium))
                        FocusDurationMenu(minutes: $minutes, accent: selected.color)
                    }
                }
                Button { model.adopt(selected, name: nickname, minutes: minutes) } label: {
                    Text("Start our journey").frame(maxWidth: .infinity)
                }.buttonStyle(PomoButtonStyle(accent: selected.color, emphasis: .primary))
                Text("Every 5 completed focus minutes earns a treat. Leftover minutes carry over.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(32)
        }
    }
}


private struct FocusDurationMenu: View {
    @Binding var minutes: Int
    let accent: Color
    @State private var hovering = false
    @SwiftUI.FocusState private var focused: Bool

    var body: some View {
        Menu {
            Picker("Focus duration", selection: $minutes) {
                ForEach(FocusState.defaultFocusPresets, id: \.self) { duration in
                    Text("\(duration) minutes").tag(duration)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "timer").foregroundStyle(accent)
                Text("\(minutes) minutes").foregroundStyle(.primary)
                Spacer(minLength: 16)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(accent)
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .padding(.horizontal, 14).frame(height: 44)
            .background(accent.opacity(hovering ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(accent.opacity(focused ? 0.9 : hovering ? 0.55 : 0.3), lineWidth: focused ? 2 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .focused($focused)
        .onHover { hovering = $0 }
        .accessibilityLabel("Focus duration")
        .accessibilityValue("\(minutes) minutes")
    }
}


final class PomoAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(UserDefaults.standard.bool(forKey: "hideDockIcon") ? .accessory : .regular)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

import SwiftUI

struct FocusTimeMenu: View {
    @ObservedObject var model: PomoModel
    @State private var pickerOpen = false
    private var accent: Color { (model.state.companion ?? .pomo).color }

    var body: some View {
        Button { pickerOpen.toggle() } label: {
            HStack(spacing: 10) {
                Image(systemName: "timer").foregroundStyle(accent)
                Text("\(model.state.nextFocusMinutes == nil ? "" : "Next: ")\(model.state.selectedFocusMinutes) min").monospacedDigit()
                Spacer(minLength: 12)
                Text("Change").foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(accent)
            }
        }
        .buttonStyle(PomoButtonStyle(accent: accent, emphasis: .primary))
        .frame(width: 264)
        .help("Change focus duration")
        .accessibilityLabel("Change focus duration, \(model.state.selectedFocusMinutes) minutes")
        .popover(isPresented: $pickerOpen, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Choose focus time", systemImage: "timer")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Button { pickerOpen = false } label: { Image(systemName: "xmark") }
                        .buttonStyle(PomoButtonStyle(accent: accent, emphasis: .quiet))
                        .accessibilityLabel("Close duration picker")
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(model.state.focusPresets, id: \.self) { minutes in
                        Button {
                            model.selectFocusMinutes(minutes)
                            pickerOpen = false
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("\(minutes)").font(.system(size: 21, weight: .semibold, design: .rounded))
                                    if minutes == model.state.selectedFocusMinutes {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption).foregroundStyle(accent)
                                    }
                                }
                                Text("minutes").font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        .buttonStyle(PomoButtonStyle(accent: accent, emphasis: minutes == model.state.selectedFocusMinutes ? .primary : .secondary))
                        .accessibilityLabel("\(minutes) minutes")
                        .accessibilityAddTraits(minutes == model.state.selectedFocusMinutes ? [.isSelected] : [])
                    }
                }
                Text("Earn 1 treat per 5 completed focus minutes. Leftover minutes carry over.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Divider()
                CustomFocusEditor(model: model) { pickerOpen = false }
                if model.state.nextFocusMinutes != nil {
                    Text("Next focus: \(model.state.selectedFocusMinutes) minutes. Your current timer is unchanged.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20).frame(width: 350)
            .background {
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    LinearGradient(colors: [accent.opacity(0.12), accent.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.22)))
        }
    }
}

struct CustomFocusEditor: View {
    @ObservedObject var model: PomoModel
    var onSave: () -> Void = {}
    @State private var input = ""
    private var minutes: Int? { Int(input.trimmingCharacters(in: .whitespacesAndNewlines)) }
    private var valid: Bool { minutes.map { (1...180).contains($0) } ?? false }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Focus duration").font(.headline)
            HStack {
                TextField("Minutes", text: $input).textFieldStyle(.plain)
                    .padding(.horizontal, 10).frame(height: 40)
                    .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.primary.opacity(0.15)))
                    .accessibilityLabel("Custom focus minutes")
                    .onSubmit { apply() }
                Text("min").foregroundStyle(.secondary)
                Button("Apply") { apply() }
                    .buttonStyle(PomoButtonStyle(accent: (model.state.companion ?? .pomo).color, emphasis: .primary))
                    .disabled(!valid)
            }
            Text("Choose 1–180 whole minutes. Changes apply to your next session if a focus timer is running or paused.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.onAppear { input = String(model.state.selectedFocusMinutes) }
    }
    private func apply() {
        guard valid, let minutes else { return }
        model.selectFocusMinutes(minutes)
        onSave()
    }
}

struct FocusTimeSettings: View {
    @ObservedObject var model: PomoModel
    @State private var presets = ""
    @State private var saved = false
    private var parsed: [Int]? {
        let parts = presets.split(separator: ",", omittingEmptySubsequences: false)
        let values = parts.compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard parts.count == values.count, !values.isEmpty, values.count <= 8,
              values.allSatisfy({ (1...180).contains($0) }), Set(values).count == values.count else { return nil }
        return values
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CustomFocusEditor(model: model)
            Divider()
            Text("Quick durations").font(.headline)
            Text("Edit the shortcuts shown in the timer menu. Enter up to eight different durations, separated by commas.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            TextField("10, 15, 25, 30, 45, 60", text: $presets)
                .textFieldStyle(.plain)
                    .padding(.horizontal, 10).frame(height: 40)
                    .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.primary.opacity(0.15))).accessibilityLabel("Quick durations in minutes")
                .onChange(of: presets) { _, _ in saved = false }
            if parsed == nil {
                Text("Use 1–8 unique whole numbers between 1 and 180.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button(saved ? "Saved" : "Save shortcuts") {
                    if let parsed { model.setFocusPresets(parsed); saved = true }
                }.disabled(parsed == nil)
                Button("Defaults") {
                    model.setFocusPresets(FocusState.defaultFocusPresets)
                    presets = FocusState.defaultFocusPresets.map(String.init).joined(separator: ", ")
                }
            }.buttonStyle(PomoButtonStyle(accent: (model.state.companion ?? .pomo).color))
            Text("Default rhythm: 25 minutes of focus, a 5-minute break, and a 15-minute break after four sessions.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { presets = model.state.focusPresets.map(String.init).joined(separator: ", ") }
    }
}

import SwiftUI

struct PomoSettingsView: View {
    @ObservedObject var model: PomoModel
    var contentWidth: CGFloat = 480
    @AppStorage("hideDockIcon") private var hideDockIcon = false
    @State private var nickname = ""
    private var accent: Color { (model.state.companion ?? .pomo).color }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Make yourself at home")
                .font(.system(size: contentWidth < 400 ? 21 : 24, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Keep Pomo in the menu bar only", isOn: $hideDockIcon)
                    .toggleStyle(.switch).tint(accent)
                Text("Hide the Dock icon. Your timer keeps running, and you can reopen Pomo or Settings from the menu bar.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16).background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            FocusTimeSettings(model: model)
            if model.state.companion != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your companion").font(.headline)
                    Text("Switch whenever you like. Your bond level, treats, focus history, name, and current timer stay with you.")
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(Companion.allCases) { companion in
                        Button { model.changeCompanion(to: companion) } label: {
                            VStack(spacing: 4) {
                                CompanionView(companion: companion, level: model.state.level)
                                    .frame(height: 90)
                                HStack(spacing: 4) {
                                    Text(companion.title)
                                    if companion == model.state.companion {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(companion.color)
                                    }
                                }.font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .frame(maxWidth: .infinity).padding(10)
                            .background(companion.color.opacity(companion == model.state.companion ? 0.15 : 0.05), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(companion == model.state.companion ? companion.color : .clear))
                        }.buttonStyle(.plain)
                            .accessibilityLabel(companion.title)
                            .accessibilityAddTraits(companion == model.state.companion ? [.isSelected] : [])
                    }
                }
                HStack {
                    TextField("Companion name", text: $nickname)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12).frame(height: 40)
                        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.25)))
                        .onSubmit { model.renameCompanion(nickname) }
                    Button("Save") { model.renameCompanion(nickname) }
                        .buttonStyle(PomoButtonStyle(accent: accent, emphasis: .primary))
                        .accessibilityLabel("Save companion name")
                }
            } else {
                Text("Choose your first companion in the main window. You can switch companions here afterward.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24).frame(width: contentWidth)
        .onAppear { nickname = model.state.nickname }
        .onChange(of: hideDockIcon) { _, hidden in
            NSApp.setActivationPolicy(hidden ? .accessory : .regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

import SwiftUI

extension Companion {
    var color: Color {
        switch self {
        case .pomo: Color(red: 0.88, green: 0.39, blue: 0.32)
        case .mori: Color(red: 0.47, green: 0.59, blue: 0.43)
        case .pip: Color(red: 0.94, green: 0.70, blue: 0.30)
        case .sprout: Color(red: 0.37, green: 0.65, blue: 0.44)
        case .nook: Color(red: 0.61, green: 0.50, blue: 0.72)
        case .ember: Color(red: 0.95, green: 0.49, blue: 0.25)
        }
    }
}

/// Resolution-independent artwork shared by onboarding and the focus screen.
struct CompanionView: View {
    let companion: Companion
    var level = 1
    var resting = false
    var reaction: CompanionReaction?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let elapsed = reaction.map { context.date.timeIntervalSince($0.startedAt) } ?? 0
            let phase = reduceMotion && reaction != nil
                ? (reaction!.grew ? CompanionReaction.Phase.growing : .happy)
                : reaction?.phase(at: context.date) ?? .idle
            let celebrating = phase == .growing || phase == .happy
            let personality = Double(Companion.allCases.firstIndex(of: companion) ?? 0)
            let cycle = (time + personality * 0.73).truncatingRemainder(dividingBy: 7)
            let blinking = !reduceMotion && cycle < 0.18
            let winking = !reduceMotion && cycle > 5.8 && cycle < 6.35
            let bob = reduceMotion ? 0 : celebrating
                ? -abs(sin(elapsed * (companion == .pip ? 9 : 6))) * (phase == .growing ? 12 : 5)
                : sin(time * 1.8 + personality) * 2.5
            Canvas { ctx, size in
                let unit = min(size.width, size.height) / 200
                ctx.translateBy(x: (size.width - 200 * unit) / 2, y: (size.height - 200 * unit) / 2)
                ctx.scaleBy(x: unit, y: unit)
                func oval(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
                }
                func rounded(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double, _ color: Color) {
                    ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r), with: .color(color))
                }
                func line(_ points: [CGPoint], _ color: Color, _ width: Double = 3) {
                    var path = Path(); path.addLines(points)
                    ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                }
                let ink = Color(red: 0.23, green: 0.23, blue: 0.21)
                let color = companion.color
                oval(48, 169, 104, 12, .black.opacity(0.07))
                ctx.translateBy(x: 0, y: bob)
                if !reduceMotion && phase != .idle {
                    let pulse = sin(elapsed * (phase == .eating ? 12 : 7))
                    ctx.translateBy(x: 100, y: 168)
                    ctx.rotate(by: .degrees(celebrating ? pulse * (companion == .nook ? 5 : 2) : 0))
                    ctx.scaleBy(x: 1 + pulse * 0.035, y: 1 - pulse * 0.025)
                    ctx.translateBy(x: -100, y: -168)
                }
                // Each silhouette has its own ears, leaves, wings, or flame.
                switch companion {
                case .pomo:
                    oval(43, 65, 114, 105, color)
                    oval(66, 48, 37, 21, .init(red: 0.40, green: 0.56, blue: 0.35))
                    oval(98, 45, 34, 23, .init(red: 0.46, green: 0.63, blue: 0.39))
                    line([.init(x: 98, y: 64), .init(x: 102, y: 44)], ink.opacity(0.6), 5)
                case .mori:
                    oval(48, 41, 34, 59, color)
                    oval(118, 41, 34, 59, color)
                    oval(42, 69, 116, 102, color)
                    oval(67, 96, 66, 66, Color(red: 0.86, green: 0.87, blue: 0.71))
                    oval(59, 51, 12, 29, .white.opacity(0.3))
                    oval(129, 51, 12, 29, .white.opacity(0.3))
                case .pip:
                    oval(47, 60, 106, 108, color)
                    oval(32, 104, 32, 43, color.opacity(0.85))
                    oval(136, 104, 32, 43, color.opacity(0.85))
                    oval(75, 41, 20, 33, color)
                    oval(96, 45, 18, 26, color)
                    oval(63, 159, 28, 10, .orange)
                    oval(111, 159, 28, 10, .orange)
                case .sprout:
                    rounded(56, 92, 88, 76, 30, Color(red: 0.78, green: 0.57, blue: 0.43))
                    rounded(50, 88, 100, 16, 7, Color(red: 0.85, green: 0.64, blue: 0.48))
                    line([.init(x: 100, y: 90), .init(x: 100, y: 55)], color, 6)
                    oval(57, 44, 45, 28, color)
                    oval(102, 33, 43, 30, color)
                    if level > 1 { oval(76, 24, 27, 28, color.opacity(0.75)) }
                case .nook:
                    rounded(39, 66, 122, 104, 40, color)
                    oval(42, 47, 35, 45, color)
                    oval(123, 47, 35, 45, color)
                    rounded(58, 93, 84, 62, 27, Color(red: 0.87, green: 0.81, blue: 0.89))
                    rounded(76, 156, 48, 15, 6, color.opacity(0.75))
                case .ember:
                    var flame = Path()
                    flame.move(to: .init(x: 100, y: 29))
                    flame.addCurve(to: .init(x: 157, y: 126), control1: .init(x: 100, y: 75), control2: .init(x: 166, y: 73))
                    flame.addCurve(to: .init(x: 43, y: 126), control1: .init(x: 154, y: 188), control2: .init(x: 37, y: 188))
                    flame.addCurve(to: .init(x: 100, y: 29), control1: .init(x: 30, y: 88), control2: .init(x: 85, y: 79))
                    ctx.fill(flame, with: .color(color))
                    oval(70, 107, 60, 51, Color(red: 1, green: 0.76, blue: 0.39))
                }
                func closedEye(_ x: Double, happy: Bool) {
                    var eye = Path()
                    eye.move(to: .init(x: x, y: 116))
                    eye.addQuadCurve(to: .init(x: x + 11, y: 116), control: .init(x: x + 5.5, y: happy ? 106 : 119))
                    ctx.stroke(eye, with: .color(ink), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                if celebrating {
                    closedEye(75, happy: true); closedEye(114, happy: true)
                } else if resting || blinking {
                    closedEye(75, happy: false); closedEye(114, happy: false)
                } else {
                    oval(77, 109, 7, 10, ink)
                    if winking { closedEye(114, happy: true) }
                    else { oval(116, 109, 7, 10, ink) }
                }
                let blush = phase == .idle ? 0.28 : 0.55
                oval(65, 123, 16, 8, .pink.opacity(blush))
                oval(120, 123, 16, 8, .pink.opacity(blush))
                if phase == .eating {
                    // Chew, then smile: the small treat travels toward the mouth.
                    let chew = reduceMotion ? 4.0 : 4 + abs(sin(elapsed * 13)) * 5
                    oval(95, 126, 10, chew, ink)
                    let progress = reduceMotion ? 0.75 : min(1, elapsed / 0.8)
                    oval(139 - progress * 34, 151 - progress * 20, 9, 9, .orange)
                } else if celebrating {
                    oval(92, 124, 16, 13, ink)
                    oval(95, 131, 10, 5, .pink.opacity(0.8))
                } else {
                    var smile = Path()
                    smile.move(to: .init(x: 94, y: 127))
                    smile.addQuadCurve(to: .init(x: 106, y: 127), control: .init(x: 100, y: resting ? 132 : 136))
                    ctx.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                if celebrating {
                    let symbols = phase == .growing ? ["✦", "✧", "✦", "✧", "✦"] : ["♥", "♥", "♥"]
                    for (index, symbol) in symbols.enumerated() {
                        let position = Double(index)
                        let rise = reduceMotion ? 0 : (elapsed * 15 + position * 7).truncatingRemainder(dividingBy: 28)
                        ctx.draw(Text(symbol).font(.system(size: phase == .growing ? 17 : 13))
                            .foregroundColor(phase == .growing ? color : .pink),
                            at: .init(x: 28 + position * (phase == .growing ? 36 : 70), y: 58 - rise))
                    }
                }
                if level > 1 {
                    // Permanent growth details are distinct for each companion.
                    switch companion {
                    case .pomo:
                        for offset in [-6.0, 0, 6] { oval(117 + offset, 49 - abs(offset), 8, 8, .pink) }
                        oval(120, 47, 5, 5, .yellow)
                    case .mori:
                        oval(49, 68, 18, 9, .green.opacity(0.7))
                        oval(56, 60, 9, 18, .green.opacity(0.7))
                    case .pip:
                        line([.init(x: 39, y: 119), .init(x: 48, y: 130)], .white.opacity(0.6))
                        line([.init(x: 152, y: 130), .init(x: 161, y: 119)], .white.opacity(0.6))
                    case .sprout:
                        oval(118, 28, 12, 12, .pink)
                        oval(130, 28, 12, 12, .pink)
                        oval(124, 21, 12, 12, .pink)
                        oval(126, 29, 7, 7, .yellow)
                    case .nook:
                        line([.init(x: 79, y: 79), .init(x: 100, y: 69), .init(x: 121, y: 79)], .white.opacity(0.6), 5)
                    case .ember:
                        oval(87, 72, 9, 16, .yellow.opacity(0.7))
                        oval(99, 62, 7, 12, .yellow.opacity(0.7))
                    }
                    ctx.draw(Text("✦").font(.system(size: 21)).foregroundColor(color), at: .init(x: 162, y: 54))
                }
                if level > 2 {
                    ctx.draw(Text("✦").font(.system(size: 14)).foregroundColor(color), at: .init(x: 32, y: 83))
                    rounded(73, 145, 54, 9, 4, .white.opacity(0.7))
                }
            }
        }
        .accessibilityLabel("\(companion.title), bond level \(level)\(reaction != nil ? (reaction!.grew ? ", celebrating growth" : ", enjoying a treat") : resting ? ", resting" : "")")
    }
}

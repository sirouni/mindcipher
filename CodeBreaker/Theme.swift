import SwiftUI

enum AppTheme {
    private static var skin: AppSkin { ThemeManager.shared.currentSkin }

    static var bgDark: Color { skin.bgColors.1 }
    static var bgCard: Color { skin.cardFill }
    static var bgCardLight: Color { skin.cardFillStrong }
    static var cardStroke: Color { skin.cardStroke }
    static var accent: Color { skin.accent }
    static var accentDim: Color { skin.accent.opacity(0.75) }
    static let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    static let danger = Color(red: 0.85, green: 0.20, blue: 0.20)
    static var textPrimary: Color { skin.textPrimary }
    static var textSecondary: Color { skin.textSecondary }
    static var textMuted: Color { skin.textMuted }

    /// Feedback marks are a game rule, not a theme accent.
    /// Teal circle / orange triangle / black cross stay the same in every skin.
    static let markExact = Color(red: 0.05, green: 0.60, blue: 0.55)
    static let markPartial = Color(red: 0.90, green: 0.52, blue: 0.05)
    static let markMiss = Color(white: 0.12)

    static var bgGradient: LinearGradient {
        let c = skin.bgColors
        return LinearGradient(
            colors: [c.0, c.1],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [bgCard, bgCardLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var glowGradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.6), accent.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func pegColor(for peg: PegColor) -> Color {
        switch peg {
        case .red: return Color(red: 0.95, green: 0.25, blue: 0.25)
        case .green: return Color(red: 0.2, green: 0.85, blue: 0.35)
        case .blue: return Color(red: 0.25, green: 0.45, blue: 0.95)
        case .yellow: return Color(red: 0.95, green: 0.85, blue: 0.15)
        case .purple: return Color(red: 0.65, green: 0.3, blue: 0.9)
        case .orange: return Color(red: 1.0, green: 0.55, blue: 0.1)
        case .cyan: return Color(red: 0.1, green: 0.85, blue: 0.9)
        case .pink: return Color(red: 0.95, green: 0.4, blue: 0.65)
        }
    }

    /// Numeral on a peg: dark ink on light chips, near-white on the two darkest.
    static func pegInk(for peg: PegColor) -> Color {
        switch peg {
        case .blue, .purple:
            return Color(white: 0.99)
        default:
            return Color(white: 0.10)
        }
    }

    static func pegInkNeedsHalo(_ peg: PegColor) -> Bool {
        switch peg {
        case .blue, .purple: return true
        default: return false
        }
    }

    static func pegGradient(for peg: PegColor) -> LinearGradient {
        let base = pegColor(for: peg)
        return LinearGradient(
            colors: [base.opacity(0.85), base, base.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(ThemeManager.shared.currentSkin.isDark ? 0.35 : 0.04), radius: 2, y: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

struct PegView: View {
    let color: PegColor
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.pegGradient(for: color))
                .frame(width: size, height: size)
                .shadow(color: AppTheme.pegColor(for: color).opacity(0.25), radius: size * 0.12, y: 1)

            Text(color.symbol)
                .font(.system(size: size * 0.6, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.pegInk(for: color))
                .shadow(
                    color: AppTheme.pegInkNeedsHalo(color) ? .black.opacity(0.28) : .clear,
                    radius: 1
                )
        }
    }
}

enum FeedbackType { case exact, partial, miss }

struct FeedbackDotView: View {
    let type: FeedbackType
    let size: CGFloat

    private var bgColor: Color {
        switch type {
        case .exact: return AppTheme.markExact.opacity(0.15)
        case .partial: return AppTheme.markPartial.opacity(0.15)
        case .miss: return Color(white: 0.88)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: size, height: size)

            Group {
                switch type {
                case .exact:
                    Circle().fill(AppTheme.markExact)
                case .partial:
                    FeedbackTriangle().fill(AppTheme.markPartial)
                case .miss:
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.9, weight: .black))
                        .foregroundStyle(AppTheme.markMiss)
                }
            }
            .frame(width: size * 0.8, height: size * 0.8)
        }
    }
}

struct FeedbackDotsRow: View {
    let feedback: Feedback
    let codeLength: Int
    var size: CGFloat = 16

    var body: some View {
        let types: [FeedbackType] =
            Array(repeating: .exact, count: feedback.exact) +
            Array(repeating: .partial, count: feedback.partial) +
            Array(repeating: .miss, count: max(0, codeLength - feedback.exact - feedback.partial))

        HStack(spacing: 3) {
            ForEach(Array(types.enumerated()), id: \.offset) { _, type in
                FeedbackDotView(type: type, size: size)
            }
        }
        .accessibilityLabel("\(feedback.exact) exact, \(feedback.partial) wrong position")
    }
}

struct FeedbackTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct MorseIndicator: View {
    let isActive: Bool
    @State private var blinkPhase = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(dotColor(index: i))
                    .frame(width: 4, height: 4)
            }
        }
        .onChange(of: isActive) { _, active in
            if active { startBlinking() }
        }
        .onAppear { if isActive { startBlinking() } }
    }

    private func dotColor(index: Int) -> Color {
        guard isActive else { return AppTheme.textMuted }
        return index == blinkPhase % 5 ? AppTheme.accent : AppTheme.textMuted
    }

    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if !isActive { timer.invalidate(); return }
            blinkPhase += 1
        }
    }
}

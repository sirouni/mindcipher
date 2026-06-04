import SwiftUI

enum AppTheme {
    private static var skin: AppSkin { ThemeManager.shared.currentSkin }

    static var bgDark: Color { skin.bgColors.1 }
    static var bgCard: Color { Color.white.opacity(0.7) }
    static var bgCardLight: Color { Color.white.opacity(0.85) }
    static var accent: Color { skin.accent }
    static var accentDim: Color { skin.accent.opacity(0.75) }
    static let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    static let danger = Color(red: 0.85, green: 0.20, blue: 0.20)
    static let textPrimary = Color(white: 0.12)
    static let textSecondary = Color(white: 0.40)
    static let textMuted = Color(white: 0.62)

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
                    .fill(Color.white.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

struct ScanlineEffect: View {
    @State private var offset: CGFloat = -200

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, AppTheme.accent.opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 100)
            .offset(y: offset)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    offset = UIScreen.main.bounds.height + 200
                }
            }
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

            if AppSettings.shared.colorBlindMode {
                Text(color.symbol)
                    .font(.system(size: size * 0.4, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
        }
    }
}

enum FeedbackType { case exact, partial, miss }

struct FeedbackDotView: View {
    let type: FeedbackType
    let size: CGFloat

    private var isColorBlind: Bool { AppSettings.shared.colorBlindMode }

    var body: some View {
        if isColorBlind {
            colorBlindShape
        } else {
            normalDot
        }
    }

    private var normalDot: some View {
        Group {
            switch type {
            case .exact:
                Circle().fill(AppTheme.accent).frame(width: size, height: size)
            case .partial:
                Circle().fill(AppTheme.warning).frame(width: size, height: size)
            case .miss:
                Circle().stroke(Color(white: 0.75), lineWidth: 1).frame(width: size, height: size)
            }
        }
    }

    @ViewBuilder
    private var colorBlindShape: some View {
        switch type {
        case .exact:
            Circle()
                .fill(AppTheme.accent)
                .frame(width: size, height: size)
                .overlay(
                    Text("E").font(.system(size: size * 0.55, weight: .black))
                        .foregroundStyle(.white)
                )
        case .partial:
            FeedbackTriangle()
                .fill(AppTheme.warning)
                .frame(width: size + 2, height: size)
                .overlay(
                    Text("P").font(.system(size: size * 0.45, weight: .black))
                        .foregroundStyle(.white)
                        .offset(y: 1)
                )
        case .miss:
            Rectangle()
                .stroke(Color(white: 0.6), lineWidth: 1.5)
                .frame(width: size - 1, height: size - 1)
        }
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

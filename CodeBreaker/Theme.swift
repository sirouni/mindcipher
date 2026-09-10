import SwiftUI

// MARK: - Tokens

enum AppTheme {
    private static var skin: AppSkin { ThemeManager.shared.currentSkin }

    /// Page background (flat paper).
    static var paper: Color { skin.paper }
    static var paperFolder: Color { skin.paperFolder }
    static var kraft: Color { skin.kraft }
    static var kraftFlap: Color { skin.kraftFlap }
    static var bgDark: Color { skin.paper }
    static var bgCard: Color { skin.paperCard }
    static var bgCardLight: Color { skin.paperCardStrong }
    static var cardStroke: Color { skin.rule }
    static var rule: Color { skin.rule }

    /// Stamp red. The only chromatic accent in the system.
    static var accent: Color { skin.stamp }
    static var accentDim: Color { skin.stamp.opacity(0.75) }
    static var danger: Color { skin.stamp }
    static var warning: Color { skin.ochre }

    static var textPrimary: Color { skin.ink }
    static var textSecondary: Color { skin.inkFaded }
    static var textMuted: Color { skin.inkMuted }
    static var ink: Color { skin.ink }

    /// Feedback marks are monochrome ink: shape carries the meaning, not colour.
    static var markExact: Color { skin.ink }
    static var markPartial: Color { skin.ink }
    static var markMiss: Color { skin.inkMuted }

    /// Okabe–Ito palette: distinguishable under protan / deutan / tritan vision.
    /// The eighth colour is ink black, which reads as a wax seal on paper.
    static func pegColor(for peg: PegColor) -> Color {
        switch peg {
        case .red: return Color(red: 0.835, green: 0.369, blue: 0.000)    // #D55E00 vermilion
        case .green: return Color(red: 0.000, green: 0.620, blue: 0.451)  // #009E73 bluish green
        case .blue: return Color(red: 0.000, green: 0.447, blue: 0.698)   // #0072B2 blue
        case .yellow: return Color(red: 0.941, green: 0.894, blue: 0.259) // #F0E442 yellow
        case .purple: return Color(red: 0.800, green: 0.475, blue: 0.655) // #CC79A7 reddish purple
        case .orange: return Color(red: 0.902, green: 0.624, blue: 0.000) // #E69F00 orange
        case .cyan: return Color(red: 0.337, green: 0.706, blue: 0.914)   // #56B4E9 sky blue
        case .pink: return Color(red: 0.10, green: 0.09, blue: 0.08)      // ink
        }
    }

    /// Numeral on a seal: dark ink on the two light chips, paper on the rest.
    static func pegInk(for peg: PegColor) -> Color {
        switch peg {
        case .yellow, .cyan, .orange:
            return Color(red: 0.10, green: 0.09, blue: 0.08)
        default:
            return Color(red: 0.97, green: 0.95, blue: 0.90)
        }
    }

    static func pegInkNeedsHalo(_ peg: PegColor) -> Bool { false }
}

// MARK: - Type

/// American Typewriter for display and labels, system for body, SF Mono for numerals.
/// Non-Latin scripts fall back to the system face automatically.
enum AppFont {
    private static func typewriterName(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy, .bold: return "AmericanTypewriter-Bold"
        case .semibold, .medium: return "AmericanTypewriter-Semibold"
        case .light, .thin, .ultraLight: return "AmericanTypewriter-Light"
        default: return "AmericanTypewriter"
        }
    }

    /// Titles, numbers that act as headings, stamps.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(typewriterName(weight), size: size, relativeTo: .body)
    }

    /// Section labels, buttons, small caps.
    static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom(typewriterName(weight), size: size, relativeTo: .body)
    }

    /// Typewriter text that is part of a drawing (peg numerals, stamps, ledger indices).
    /// Fixed size: it must fit the shape it sits in regardless of Dynamic Type.
    static func graphic(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(typewriterName(weight), fixedSize: size)
    }

    /// System fonts don't follow Dynamic Type when given a point size; scale by hand so
    /// body/mono keep pace with the typewriter faces.
    private static func scaled(_ size: CGFloat) -> CGFloat {
        UIFontMetrics(forTextStyle: .body).scaledValue(for: size)
    }

    /// Running text.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: scaled(size), weight: weight)
    }

    /// Case numbers, counters, seeds.
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: scaled(size), weight: weight, design: .monospaced)
    }
}

// MARK: - Paper surfaces

struct PaperCard: ViewModifier {
    var cornerRadius: CGFloat = 4
    var fill: Color? = nil
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fill ?? AppTheme.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.rule, lineWidth: 1)
                    )
            )
    }
}

extension View {
    /// Sheet of paper laid on the page: flat fill, hairline ink stroke, no shadow.
    func paperCard(cornerRadius: CGFloat = 4, fill: Color? = nil) -> some View {
        modifier(PaperCard(cornerRadius: cornerRadius, fill: fill))
    }

    /// Legacy name kept for call sites that have not been touched yet.
    func glassCard(cornerRadius: CGFloat = 4) -> some View {
        modifier(PaperCard(cornerRadius: min(cornerRadius, 6)))
    }
}

/// 档案袋: kraft body, folded flap, string-and-washer, gummed label, optional stamp.
struct ArchivePouchView: View {
    enum Footer { case stars(Int), pro, locked, empty }

    let number: Int
    var isCompleted: Bool
    var isMuted: Bool
    var isNext: Bool
    var nextTone: Color = AppTheme.ink
    var footer: Footer = .empty

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                drawPouch(ctx: &ctx, size: size)
            }

            VStack(spacing: 0) {
                Color.clear.frame(height: 22)

                Text("\(number)")
                    .font(AppFont.graphic(number >= 100 ? 10 : 12, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(isMuted ? AppTheme.textMuted : AppTheme.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(AppTheme.ink.opacity(0.18))
                            .offset(x: 0.8, y: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(AppTheme.bgCardLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 1)
                            .stroke(AppTheme.ink.opacity(isMuted ? 0.25 : 0.45), lineWidth: 0.8)
                    )

                if isCompleted {
                    Text(L("case.closed"))
                        .font(AppFont.graphic(5.5, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .stroke(AppTheme.accent, lineWidth: 1.2)
                        )
                        .padding(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(AppTheme.accent, lineWidth: 0.7)
                        )
                        .rotationEffect(.degrees(-6))
                        .padding(.top, 5)
                        .padding(.bottom, 6)
                }

                Spacer(minLength: 6)

                footerView
                    .frame(height: 12)
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, minHeight: 102)
        .accessibilityElement(children: .ignore)
    }

    @ViewBuilder
    private var footerView: some View {
        switch footer {
        case .stars(let count):
            HStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < count ? "star.fill" : "star")
                        .font(.system(size: 7))
                        .foregroundStyle(i < count ? AppTheme.accent : AppTheme.textMuted.opacity(0.55))
                }
            }
        case .pro:
            Text("PRO")
                .font(AppFont.label(6, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(AppTheme.accent)
        case .locked:
            Image(systemName: "lock")
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textMuted)
        case .empty:
            Color.clear.frame(height: 8)
        }
    }

    private func drawPouch(ctx: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let flapH: CGFloat = 18
        let outline = pouchOutline(in: rect, flapH: flapH)
        let flap = flapOutline(in: rect, flapH: flapH)
        let kraft = isMuted ? AppTheme.bgCard : AppTheme.kraft
        let flapColor = isMuted ? AppTheme.paperFolder : AppTheme.kraftFlap
        let ink = (isMuted ? AppTheme.textMuted : AppTheme.ink).opacity(0.85)
        let stroke = isNext ? nextTone : AppTheme.ink.opacity(0.55)

        var back = outline
        back = back.offsetBy(dx: 1.6, dy: 2.2)
        ctx.fill(back, with: .color(AppTheme.ink.opacity(0.16)))

        ctx.fill(outline, with: .color(kraft))
        ctx.fill(flap, with: .color(flapColor))

        var seam = Path()
        seam.move(to: CGPoint(x: 1, y: flapH))
        seam.addLine(to: CGPoint(x: size.width - 1, y: flapH))
        ctx.stroke(seam, with: .color(AppTheme.ink.opacity(0.28)), lineWidth: 1)

        var gusset = Path()
        gusset.move(to: CGPoint(x: 5, y: flapH + 1))
        gusset.addLine(to: CGPoint(x: 5, y: size.height - 6))
        gusset.move(to: CGPoint(x: size.width - 5, y: flapH + 1))
        gusset.addLine(to: CGPoint(x: size.width - 5, y: size.height - 6))
        ctx.stroke(gusset, with: .color(AppTheme.ink.opacity(0.1)), lineWidth: 0.7)

        var grain = Path()
        grain.move(to: CGPoint(x: 10, y: flapH + 8))
        grain.addLine(to: CGPoint(x: size.width - 14, y: flapH + 11))
        grain.move(to: CGPoint(x: 14, y: size.height * 0.62))
        grain.addLine(to: CGPoint(x: size.width - 11, y: size.height * 0.58))
        ctx.stroke(grain, with: .color(AppTheme.ink.opacity(0.06)), lineWidth: 0.6)

        ctx.stroke(outline, with: .color(stroke), lineWidth: isNext ? 1.6 : 1.1)

        let midX = size.width * 0.5
        let top = CGPoint(x: midX, y: 6.5)
        let bot = CGPoint(x: midX, y: 16.5)
        let bulge = size.width * 0.16
        var cord = Path()
        cord.move(to: top)
        cord.addCurve(
            to: bot,
            control1: CGPoint(x: midX + bulge, y: 9),
            control2: CGPoint(x: midX + bulge, y: 14)
        )
        cord.addCurve(
            to: top,
            control1: CGPoint(x: midX - bulge, y: 14),
            control2: CGPoint(x: midX - bulge, y: 9)
        )
        ctx.stroke(cord, with: .color(ink), style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round))

        drawWasher(&ctx, at: top, radius: 3.4, ink: ink)
        drawWasher(&ctx, at: bot, radius: 3.4, ink: ink)
    }

    private func drawWasher(_ ctx: inout GraphicsContext, at center: CGPoint, radius: CGFloat, ink: Color) {
        let outer = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: outer), with: .color(AppTheme.kraftFlap))
        ctx.stroke(Path(ellipseIn: outer), with: .color(ink), lineWidth: 1.15)
        let holeR = radius * 0.38
        let hole = CGRect(x: center.x - holeR, y: center.y - holeR, width: holeR * 2, height: holeR * 2)
        ctx.fill(Path(ellipseIn: hole), with: .color(AppTheme.kraft))
        ctx.stroke(Path(ellipseIn: hole), with: .color(ink), lineWidth: 0.7)
    }

    private func pouchOutline(in rect: CGRect, flapH: CGFloat) -> Path {
        let cr: CGFloat = 2.2
        let inset: CGFloat = 5
        var p = Path()
        p.move(to: CGPoint(x: inset, y: 1))
        p.addLine(to: CGPoint(x: rect.width - inset, y: 1))
        p.addLine(to: CGPoint(x: rect.width - 0.6, y: flapH))
        p.addLine(to: CGPoint(x: rect.width, y: flapH + 1.5))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - cr))
        p.addQuadCurve(
            to: CGPoint(x: rect.width - cr, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )
        p.addLine(to: CGPoint(x: cr, y: rect.height))
        p.addQuadCurve(to: CGPoint(x: 0, y: rect.height - cr), control: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: flapH + 1.5))
        p.addLine(to: CGPoint(x: 0.6, y: flapH))
        p.closeSubpath()
        return p
    }

    private func flapOutline(in rect: CGRect, flapH: CGFloat) -> Path {
        let inset: CGFloat = 5
        var p = Path()
        p.move(to: CGPoint(x: inset, y: 1))
        p.addLine(to: CGPoint(x: rect.width - inset, y: 1))
        p.addLine(to: CGPoint(x: rect.width - 0.6, y: flapH))
        p.addLine(to: CGPoint(x: 0.6, y: flapH))
        p.closeSubpath()
        return p
    }
}

/// Dotted typewriter rule.
struct TypewriterRule: View {
    var color: Color = AppTheme.rule
    var dotted: Bool = true
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0.5))
                p.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: dotted ? [2, 3] : []))
        }
        .frame(height: 1)
    }
}

/// Rubber stamp: uppercase typewriter text inside a double border, slightly rotated.
struct StampView: View {
    enum Tone { case red, ink }
    let text: String
    var tone: Tone = .red
    var size: CGFloat = 11
    var rotation: Double = -6

    private var color: Color { tone == .red ? AppTheme.accent : AppTheme.ink }

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.graphic(size, weight: .bold))
            .tracking(size * 0.18)
            .foregroundStyle(color)
            .padding(.horizontal, size * 0.6)
            .padding(.vertical, size * 0.3)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(color, lineWidth: 2)
            )
            .padding(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color, lineWidth: 1)
            )
            .opacity(0.88)
            .rotationEffect(.degrees(rotation))
            .accessibilityLabel(text)
    }
}

/// Small uppercase typewriter caption used above sections.
struct DossierCaption: View {
    let text: String
    var color: Color = AppTheme.textSecondary
    var body: some View {
        Text(text.uppercased())
            .font(AppFont.label(11, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(color)
    }
}

/// One ledger line: roman numeral index, content, trailing marks.
struct LedgerRow<Content: View, Trailing: View>: View {
    let index: Int
    var highlighted: Bool = false
    @ViewBuilder let content: () -> Content
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            Text(romanNumeral(index))
                .font(AppFont.graphic(11, weight: highlighted ? .bold : .regular))
                .foregroundStyle(highlighted ? AppTheme.accent : AppTheme.textSecondary)
                .frame(width: 26, alignment: .leading)
            content()
            Spacer(minLength: 6)
            trailing()
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { TypewriterRule() }
    }
}

func romanNumeral(_ n: Int) -> String {
    guard n > 0 else { return "—" }
    let table: [(Int, String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
        (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]
    var value = n
    var out = ""
    for (v, s) in table {
        while value >= v { out += s; value -= v }
    }
    return out
}

// MARK: - Pegs (wax seals)

/// Distinct outline per colour, used when the shape-marks setting is on.
struct PegSealShape: Shape {
    let index: Int

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        func polygon(_ sides: Int, rotate: CGFloat = -.pi / 2) {
            for i in 0..<sides {
                let a = rotate + CGFloat(i) * 2 * .pi / CGFloat(sides)
                let pt = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
        switch index % 8 {
        case 0: p.addEllipse(in: rect)
        case 1: p.addRoundedRect(in: rect.insetBy(dx: r * 0.08, dy: r * 0.08), cornerSize: CGSize(width: r * 0.18, height: r * 0.18))
        case 2: polygon(3)
        case 3: polygon(4)
        case 4: polygon(6)
        case 5: polygon(5)
        case 6:
            for i in 0..<10 {
                let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
                let rr = i % 2 == 0 ? r : r * 0.5
                let pt = CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        default:
            let w = r * 0.62
            p.addRoundedRect(in: CGRect(x: c.x - w / 2, y: c.y - r, width: w, height: r * 2), cornerSize: CGSize(width: 2, height: 2))
            p.addRoundedRect(in: CGRect(x: c.x - r, y: c.y - w / 2, width: r * 2, height: w), cornerSize: CGSize(width: 2, height: 2))
        }
        return p
    }
}

struct PegView: View {
    let color: PegColor
    let size: CGFloat
    @AppStorage("settings_colorBlind") private var shapeMarks = false

    private var fill: Color { AppTheme.pegColor(for: color) }
    private var ring: Color { ThemeManager.shared.currentSkin.isDark ? Color(red: 0.97, green: 0.95, blue: 0.90).opacity(0.85) : Color(red: 0.10, green: 0.09, blue: 0.08) }
    private var innerRing: Color { AppTheme.pegInk(for: color).opacity(0.55) }

    var body: some View {
        ZStack {
            if shapeMarks {
                PegSealShape(index: color.rawValue)
                    .fill(fill)
                    .frame(width: size, height: size)
                PegSealShape(index: color.rawValue)
                    .stroke(ring, lineWidth: max(1.5, size * 0.08))
                    .frame(width: size, height: size)
            } else {
                Circle()
                    .fill(fill)
                    .frame(width: size, height: size)
                Circle()
                    .stroke(ring, lineWidth: max(1.5, size * 0.08))
                    .frame(width: size, height: size)
                Circle()
                    .stroke(innerRing, lineWidth: max(1, size * 0.05))
                    .frame(width: size * 0.72, height: size * 0.72)
            }

            Text(color.symbol)
                .font(AppFont.graphic(size * 0.5, weight: .bold))
                .foregroundStyle(AppTheme.pegInk(for: color))
        }
        .accessibilityLabel(color.displayName)
    }
}

// MARK: - Feedback marks (ink only)

enum FeedbackType { case exact, partial, miss }

struct FeedbackDotView: View {
    let type: FeedbackType
    let size: CGFloat

    var body: some View {
        ZStack {
            switch type {
            case .exact:
                Circle()
                    .fill(AppTheme.markExact)
                    .frame(width: size * 0.8, height: size * 0.8)
            case .partial:
                Circle()
                    .stroke(AppTheme.markPartial, lineWidth: max(1.5, size * 0.13))
                    .frame(width: size * 0.72, height: size * 0.72)
            case .miss:
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppTheme.markMiss)
                    .frame(width: size * 0.6, height: max(1.5, size * 0.12))
            }
        }
        .frame(width: size, height: size)
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

/// Primary action: full-width ink bar with paper text.
struct InkButtonStyle: ButtonStyle {
    var prominent: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.label(14, weight: .bold))
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(prominent ? AppTheme.paper : AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(prominent ? AppTheme.ink : AppTheme.bgCardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(AppTheme.ink, lineWidth: prominent ? 0 : 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
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

extension View {
    /// Pegs, slots, and notes are positional — keep P1 on the left in every language.
    func boardLayout() -> some View {
        environment(\.layoutDirection, .leftToRight)
    }
}

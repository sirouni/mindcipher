import SwiftUI

/// Dossier cover: paper, a typewriter title, one red stamp slammed in.
struct SplashView: View {
    @State private var coverOpacity: Double = 0
    @State private var titleOffset: CGFloat = 16
    @State private var titleOpacity: Double = 0
    @State private var stampScale: CGFloat = 1.8
    @State private var stampOpacity: Double = 0
    @State private var ruleWidth: CGFloat = 0
    @State private var finished = false

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    DossierCaption(text: L("app.subtitle"))
                        .opacity(titleOpacity)

                    Text(L("app.title").uppercased())
                        .font(AppFont.display(38, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Rectangle()
                        .fill(AppTheme.ink)
                        .frame(width: ruleWidth, height: 2)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("FILE")
                            .font(AppFont.label(11, weight: .regular))
                            .tracking(2)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(String(format: "No. %04d", DailyCalendar.dayNumber()))
                            .font(AppFont.label(11, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .opacity(titleOpacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 36)
                .overlay(alignment: .topTrailing) {
                    StampView(text: "Top Secret", tone: .red, size: 14, rotation: -14)
                        .scaleEffect(stampScale)
                        .opacity(stampOpacity)
                        .padding(.trailing, 30)
                        .offset(y: -28)
                }

                Spacer()
                Spacer()
            }
            .opacity(coverOpacity)
        }
        .opacity(finished ? 0 : 1)
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.easeOut(duration: 0.25)) {
            coverOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
            titleOffset = 0
            titleOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.35)) {
            ruleWidth = 120
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.75)) {
            stampScale = 1
            stampOpacity = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                finished = true
            }
        }
    }
}

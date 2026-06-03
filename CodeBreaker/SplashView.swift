import SwiftUI

struct SplashView: View {
    @State private var phase = 0
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var scanAngle: Double = 0
    @State private var finished = false

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.1), lineWidth: 1)
                        .frame(width: 180, height: 180)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.accent.opacity(0.4), .clear],
                                center: .center
                            ),
                            lineWidth: 60
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(scanAngle))
                        .opacity(ringOpacity)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.accent)
                        .shadow(color: AppTheme.accent.opacity(0.6), radius: 25)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 6) {
                    Text("Code Breaker")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("CODE BREAKER")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.accent)
                        .tracking(6)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .opacity(finished ? 0 : 1)
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }

        withAnimation(.linear(duration: 2).delay(0.3)) {
            scanAngle = 360
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                finished = true
            }
        }
    }
}

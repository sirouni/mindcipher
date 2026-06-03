import SwiftUI

@main
struct CodeBreakerApp: App {
    @State private var showSplash = true
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                if showSplash {
                    SplashView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .preferredColorScheme(.light)
            .id(themeManager.currentSkin.rawValue)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    showSplash = false
                }
            }
        }
    }
}

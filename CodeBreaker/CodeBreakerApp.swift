import SwiftUI

@main
struct CodeBreakerApp: App {
    @State private var showSplash = true

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
            .preferredColorScheme(.dark)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    showSplash = false
                }
            }
        }
    }
}

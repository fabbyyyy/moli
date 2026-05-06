import SwiftUI

@main
struct moliApp: App {
    @State private var showSplash = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasSeenOnboarding {
                    MainTabView()
                        .opacity(showSplash ? 0 : 1)
                } else {
                    OnboardingView()
                        .opacity(showSplash ? 0 : 1)
                }

                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.4), value: showSplash)
            .task {
                try? await Task.sleep(for: .milliseconds(1200))
                showSplash = false
            }
        }
    }
}

private struct SplashScreen: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            AppTheme.Colors.primaryBlue.ignoresSafeArea()

            Image("moli")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .scaleEffect(pulse ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear { pulse = true }
    }
}

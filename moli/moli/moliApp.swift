import SwiftUI

@main
struct moliApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .opacity(showSplash ? 0 : 1)

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

            VStack(spacing: 16) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                Text("Moli")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Tu copiloto de ruta")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .onAppear { pulse = true }
    }
}

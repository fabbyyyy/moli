import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "house")
                }

            NavigationStack {
                RouteMapView()
            }
                .tabItem {
                    Label("Tu Ruta", systemImage: "map")
                }

            DailyOrdersView()
                .tabItem {
                    Label("Histórico", systemImage: "clock.arrow.circlepath")
                }
        }
        .tint(AppTheme.Colors.primaryBlue)
    }
}

#Preview {
    MainTabView()
}

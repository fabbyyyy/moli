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
                    Label("Pedidos", systemImage: "shippingbox")
                }
        }
        .tint(AppTheme.Colors.primaryBlue)
    }
}

#Preview {
    MainTabView()
}

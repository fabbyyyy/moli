import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Inicio", systemImage: "house")
                }
                .tag(0)

            NavigationStack {
                RouteMapView()
            }
                .tabItem {
                    Label("Tu Ruta", systemImage: "map")
                }
                .tag(1)

            DailyOrdersView()
                .tabItem {
                    Label("Pedidos", systemImage: "shippingbox")
                }
                .tag(2)
        }
        .tint(AppTheme.Colors.primaryBlue)
    }
}

#Preview {
    MainTabView()
}

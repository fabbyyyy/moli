import Foundation
import Observation

struct ProductExpirationAlert: Identifiable, Hashable {
    let id = UUID()
    let productName: String
    let storeName: String
    let quantity: Int
    let daysUntilExpiration: Int
}

struct ReadyOrderSummary: Identifiable, Hashable {
    let id = UUID()
    let storeName: String
    let pieces: Int
    let totalMXN: Int
}

@Observable
final class HomeViewModel {
    var userName: String = "Luis"
    var currentRouteName: String = "Ruta 14"
    var completedStores: Int = 3
    var totalStores: Int = 8
    var nextStoreName: String = "Abarrotes El Pino"
    var expiringProductAlerts: [ProductExpirationAlert] = [
        ProductExpirationAlert(productName: "Donas Glaseadas", storeName: "Abarrotes El Pino", quantity: 2, daysUntilExpiration: 2),
        ProductExpirationAlert(productName: "Pan Blanco Grande", storeName: "Tiendita El Sol", quantity: 4, daysUntilExpiration: 3),
        ProductExpirationAlert(productName: "Gansito Choco", storeName: "Mini Súper Guadalupe", quantity: 3, daysUntilExpiration: 4)
    ]
    var readyOrderSummaries: [ReadyOrderSummary] = []
    
    func loadDashboard() {
        let routeStops = LocalPersistenceService.shared.currentRoute
        let completed = routeStops.filter { $0.isCompleted }.count
        self.completedStores = completed
        self.totalStores = routeStops.count
        
        if let next = routeStops.first(where: { !$0.isCompleted }) {
            self.nextStoreName = next.store.name
        }
        
        self.readyOrderSummaries = LocalPersistenceService.shared.dailyOrders.map { order in
            ReadyOrderSummary(
                storeName: order.store.name,
                pieces: order.totalPieces,
                totalMXN: order.totalPieces * 15
            )
        }
    }
}

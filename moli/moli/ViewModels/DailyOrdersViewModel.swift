import Foundation
import Observation

@Observable
final class DailyOrdersViewModel {
    var currentCart: WeeklyOrder = LocalPersistenceService.shared.weeklyOrderCart
    var orders: [WeeklyOrder] = []

    var currentOrder: WeeklyOrder? {
        if !currentCart.entries.isEmpty {
            return currentCart
        }
        return nil
    }

    var currentOrderIsPendingConfirmation: Bool {
        !currentCart.entries.isEmpty
    }

    var historyOrders: [WeeklyOrder] {
        return orders
    }

    var recentHistoryOrders: [WeeklyOrder] {
        Array(historyOrders.prefix(3))
    }

    var hasMoreHistoryOrders: Bool {
        historyOrders.count > recentHistoryOrders.count
    }
    
    var totalWasteAvoided: Double {
        currentCart.avoidedWasteMXN + orders.reduce(0) { $0 + $1.avoidedWasteMXN }
    }
    
    var totalPieces: Int {
        currentCart.totalPieces + orders.reduce(0) { $0 + $1.totalPieces }
    }
    
    var totalStoreEntries: Int {
        currentCart.storeCount + orders.reduce(0) { $0 + $1.storeCount }
    }
    
    var completedStores: Int = 0
    var totalRouteStores: Int = 0
    
    func loadOrders() {
        self.currentCart = LocalPersistenceService.shared.weeklyOrderCart
        self.orders = LocalPersistenceService.shared.weeklyOrders
        
        let routeStops = LocalPersistenceService.shared.currentRoute
        self.completedStores = routeStops.filter { $0.isCompleted }.count
        self.totalRouteStores = routeStops.count
    }
    
    func confirmOrder() {
        LocalPersistenceService.shared.finalizeWeeklyOrderCart()
        loadOrders()
    }
}

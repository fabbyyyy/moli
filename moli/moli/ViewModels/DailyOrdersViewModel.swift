import Foundation
import Observation

@Observable
final class DailyOrdersViewModel {
    var currentCart: WeeklyOrder = LocalPersistenceService.shared.weeklyOrderCart
    var orders: [WeeklyOrder] = []
    
    var totalWasteAvoided: Double {
        currentCart.avoidedWasteMXN + orders.reduce(0) { $0 + $1.avoidedWasteMXN }
    }
    
    var totalPieces: Int {
        currentCart.totalPieces + orders.reduce(0) { $0 + $1.totalPieces }
    }
    
    var totalStoreEntries: Int {
        currentCart.storeCount + orders.reduce(0) { $0 + $1.storeCount }
    }
    
    func loadOrders() {
        self.currentCart = LocalPersistenceService.shared.weeklyOrderCart
        self.orders = LocalPersistenceService.shared.weeklyOrders
    }
}

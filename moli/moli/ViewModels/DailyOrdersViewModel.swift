import Foundation
import Observation

@Observable
final class DailyOrdersViewModel {
    var orders: [Order] = []
    
    var totalWasteAvoided: Double {
        orders.reduce(0) { $0 + $1.avoidedWasteMXN }
    }
    
    var totalPieces: Int {
        orders.reduce(0) { $0 + $1.totalPieces }
    }
    
    func loadOrders() {
        self.orders = LocalPersistenceService.shared.dailyOrders
    }
}

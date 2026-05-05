import Foundation
import Combine

class LocalPersistenceService: ObservableObject {
    static let shared = LocalPersistenceService()
    
    @Published var stores: [Store] = []
    @Published var currentRoute: [RouteStop] = []
    @Published var dailyOrders: [Order] = []
    
    private init() {
        // Initialize with mock data for MVP demo
        self.stores = MockStores.allStores
        self.currentRoute = MockRouteStops.todayRoute
        self.dailyOrders = MockOrders.dummyOrders
    }
    
    func getInventory(for storeId: UUID) -> [InventoryItem] {
        return MockInventory.getInventory(for: storeId)
    }
    
    func getSalesHistory(for storeId: UUID) -> [SalesHistory] {
        return MockSalesHistory.getHistory(for: storeId)
    }
    
    func saveOrder(_ order: Order) {
        dailyOrders.append(order)
        // In a real app with SwiftData, this would insert into the ModelContext
        if let index = currentRoute.firstIndex(where: { $0.store.id == order.store.id }) {
            currentRoute[index].isCompleted = true
        }
    }
}

import Foundation
import Combine

class LocalPersistenceService: ObservableObject {
    static let shared = LocalPersistenceService()
    
    @Published var stores: [Store] = []
    @Published var currentRoute: [RouteStop] = []
    @Published var weeklyOrderCart: WeeklyOrder
    @Published var weeklyOrders: [WeeklyOrder] = []
    
    private init() {
        // Initialize with mock data for MVP demo
        self.stores = MockStores.allStores
        self.currentRoute = MockRouteStops.todayRoute
        self.weeklyOrderCart = Self.makeEmptyWeeklyCart(routeName: "Ruta 14")
        self.weeklyOrders = MockOrders.dummyWeeklyOrders
    }
    
    func getInventory(for storeId: UUID) -> [InventoryItem] {
        return MockInventory.getInventory(for: storeId)
    }
    
    func getSalesHistory(for storeId: UUID) -> [SalesHistory] {
        return MockSalesHistory.getHistory(for: storeId)
    }
    
    func addOrderSuggestionToCart(_ order: Order) {
        let entry = WeeklyOrderStoreEntry(
            id: UUID(),
            store: order.store,
            recommendations: order.recommendations,
            totalPieces: order.totalPieces,
            avoidedWasteMXN: order.avoidedWasteMXN,
            addedAt: Date()
        )
        
        if let existingIndex = weeklyOrderCart.entries.firstIndex(where: { $0.store.id == order.store.id }) {
            weeklyOrderCart.entries[existingIndex] = entry
        } else {
            weeklyOrderCart.entries.append(entry)
        }
        
        if let index = currentRoute.firstIndex(where: { $0.store.id == order.store.id }) {
            currentRoute[index].isCompleted = true
        }
    }
    
    func finalizeWeeklyOrderCart() {
        guard !weeklyOrderCart.entries.isEmpty else {
            return
        }
        
        weeklyOrderCart.status = .readyForNextWeek
        weeklyOrderCart.finalizedAt = Date()
        weeklyOrders.insert(weeklyOrderCart, at: 0)
        weeklyOrderCart = Self.makeEmptyWeeklyCart(routeName: weeklyOrderCart.routeName)
    }
    
    func saveOrder(_ order: Order) {
        addOrderSuggestionToCart(order)
    }
    
    private static func makeEmptyWeeklyCart(routeName: String) -> WeeklyOrder {
        WeeklyOrder(
            id: UUID(),
            routeName: routeName,
            createdAt: Date(),
            targetWeekStartDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            finalizedAt: nil,
            entries: [],
            status: .cart
        )
    }
}

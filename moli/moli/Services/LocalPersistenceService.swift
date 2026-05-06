import Foundation
import Combine

class LocalPersistenceService: ObservableObject {
    static let shared = LocalPersistenceService()
    
    @Published var stores: [Store] = []
    @Published var currentRoute: [RouteStop] = []
    @Published var weeklyOrderCart: WeeklyOrder
    @Published var weeklyOrders: [WeeklyOrder] = []
    
    private let weeklyOrdersKey = "saved_weekly_orders"
    private let cartKey = "saved_weekly_cart"
    
    private init() {
        // Initialize with mock data for MVP demo
        self.stores = MockStores.allStores
        self.currentRoute = MockRouteStops.todayRoute
        
        if let data = UserDefaults.standard.data(forKey: cartKey),
           let savedCart = try? JSONDecoder().decode(WeeklyOrder.self, from: data) {
            self.weeklyOrderCart = savedCart
        } else {
            self.weeklyOrderCart = Self.makeEmptyWeeklyCart(routeName: "Ruta 14")
        }
        
        if let data = UserDefaults.standard.data(forKey: weeklyOrdersKey),
           let savedOrders = try? JSONDecoder().decode([WeeklyOrder].self, from: data) {
            self.weeklyOrders = savedOrders
        } else {
            self.weeklyOrders = MockOrders.dummyWeeklyOrders
        }
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
        
        saveState()
    }
    
    func finalizeWeeklyOrderCart() {
        guard !weeklyOrderCart.entries.isEmpty else {
            return
        }
        
        weeklyOrderCart.status = .readyForNextWeek
        weeklyOrderCart.finalizedAt = Date()
        weeklyOrders.insert(weeklyOrderCart, at: 0)
        weeklyOrderCart = Self.makeEmptyWeeklyCart(routeName: weeklyOrderCart.routeName)
        
        saveState()
    }
    
    func saveOrder(_ order: Order) {
        addOrderSuggestionToCart(order)
    }
    
    private func saveState() {
        if let cartData = try? JSONEncoder().encode(weeklyOrderCart) {
            UserDefaults.standard.set(cartData, forKey: cartKey)
        }
        if let ordersData = try? JSONEncoder().encode(weeklyOrders) {
            UserDefaults.standard.set(ordersData, forKey: weeklyOrdersKey)
        }
    }
    
    private static func makeEmptyWeeklyCart(routeName: String) -> WeeklyOrder {
        WeeklyOrder(
            id: UUID(),
            routeName: routeName,
            createdAt: Date(),
            targetWeekStartDate: Self.nextTuesday(from: Date()),
            finalizedAt: nil,
            entries: [],
            status: .cart
        )
    }

    private static func nextTuesday(from date: Date) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        let currentWeekday = calendar.component(.weekday, from: startOfToday)
        let tuesday = 3
        let rawDaysUntilTuesday = (tuesday - currentWeekday + 7) % 7
        let daysUntilTuesday = rawDaysUntilTuesday == 0 ? 7 : rawDaysUntilTuesday
        return calendar.date(byAdding: .day, value: daysUntilTuesday, to: startOfToday) ?? date
    }
}

import Foundation

struct MockSalesHistory {
    static func getHistory(for storeId: UUID) -> [SalesHistory] {
        return [
            // Just some dummy data for now
            SalesHistory(id: UUID(), storeId: storeId, productId: MockProducts.panBlanco.id, weekNumber: 15, unitsSold: 12, unitsReturned: 0, demandTrend: 0.1),
            SalesHistory(id: UUID(), storeId: storeId, productId: MockProducts.panBlanco.id, weekNumber: 16, unitsSold: 14, unitsReturned: 0, demandTrend: 0.15),
            SalesHistory(id: UUID(), storeId: storeId, productId: MockProducts.gansito.id, weekNumber: 15, unitsSold: 20, unitsReturned: 2, demandTrend: -0.05),
            SalesHistory(id: UUID(), storeId: storeId, productId: MockProducts.gansito.id, weekNumber: 16, unitsSold: 22, unitsReturned: 1, demandTrend: 0.05)
        ]
    }
}

import Foundation

struct SalesHistory: Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let productId: UUID
    let weekNumber: Int
    let unitsSold: Int
    let unitsReturned: Int
    let demandTrend: Double
}

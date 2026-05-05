import Foundation

enum WeeklyOrderStatus: String, Hashable {
    case cart
    case readyForNextWeek
    case sentSimulated
    case pendingSync
}

struct WeeklyOrderStoreEntry: Identifiable, Hashable {
    let id: UUID
    let store: Store
    var recommendations: [Recommendation]
    var totalPieces: Int
    var avoidedWasteMXN: Double
    let addedAt: Date
}

struct WeeklyOrder: Identifiable, Hashable {
    let id: UUID
    let routeName: String
    let createdAt: Date
    let targetWeekStartDate: Date
    var finalizedAt: Date?
    var entries: [WeeklyOrderStoreEntry]
    var status: WeeklyOrderStatus
    
    var totalPieces: Int {
        entries.reduce(0) { $0 + $1.totalPieces }
    }
    
    var avoidedWasteMXN: Double {
        entries.reduce(0) { $0 + $1.avoidedWasteMXN }
    }
    
    var storeCount: Int {
        entries.count
    }
}

import Foundation

struct MockOrders {
    static let dummyOrders: [Order] = [
        Order(id: UUID(), store: MockStores.allStores[1], recommendations: [], date: Date().addingTimeInterval(-3600*2), totalPieces: 28, avoidedWasteMXN: 45.0, status: .sentSimulated),
        Order(id: UUID(), store: MockStores.allStores[2], recommendations: [], date: Date().addingTimeInterval(-3600), totalPieces: 36, avoidedWasteMXN: 120.0, status: .sentSimulated)
    ]
}

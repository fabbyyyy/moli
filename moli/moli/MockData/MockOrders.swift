import Foundation

struct MockOrders {
    static let dummyOrders: [Order] = [
        Order(id: UUID(), store: MockStores.allStores[1], recommendations: [], date: Date().addingTimeInterval(-3600*2), totalPieces: 28, avoidedWasteMXN: 45.0, status: .sentSimulated),
        Order(id: UUID(), store: MockStores.allStores[2], recommendations: [], date: Date().addingTimeInterval(-3600), totalPieces: 36, avoidedWasteMXN: 120.0, status: .sentSimulated)
    ]
    
    static let dummyWeeklyOrders: [WeeklyOrder] = [
        WeeklyOrder(
            id: UUID(),
            routeName: "Ruta 14",
            createdAt: Date().addingTimeInterval(-86_400 * 2),
            targetWeekStartDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            finalizedAt: Date().addingTimeInterval(-3_600),
            entries: [
                WeeklyOrderStoreEntry(
                    id: UUID(),
                    store: MockStores.allStores[1],
                    recommendations: [],
                    totalPieces: 28,
                    avoidedWasteMXN: 45.0,
                    addedAt: Date().addingTimeInterval(-7_200)
                ),
                WeeklyOrderStoreEntry(
                    id: UUID(),
                    store: MockStores.allStores[2],
                    recommendations: [],
                    totalPieces: 36,
                    avoidedWasteMXN: 120.0,
                    addedAt: Date().addingTimeInterval(-3_600)
                )
            ],
            status: .readyForNextWeek
        )
    ]
}

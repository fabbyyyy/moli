import Foundation

struct MockOrders {
    static let dummyOrders: [Order] = [
        Order(id: UUID(), store: MockStores.allStores[1], recommendations: recommendationsA, date: Date().addingTimeInterval(-3600 * 2), totalPieces: 28, avoidedWasteMXN: 45.0, status: .sentSimulated),
        Order(id: UUID(), store: MockStores.allStores[2], recommendations: recommendationsB, date: Date().addingTimeInterval(-3600), totalPieces: 36, avoidedWasteMXN: 120.0, status: .sentSimulated)
    ]

    static let dummyWeeklyOrders: [WeeklyOrder] = [
        weeklyOrder(daysAgo: 1, targetDaysAhead: 6, entries: [
            storeEntry(storeIndex: 1, recommendations: recommendationsA, hoursAgo: 7),
            storeEntry(storeIndex: 2, recommendations: recommendationsB, hoursAgo: 3)
        ]),
        weeklyOrder(daysAgo: 8, targetDaysAhead: -1, entries: [
            storeEntry(storeIndex: 0, recommendations: recommendationsC, hoursAgo: 24 * 8),
            storeEntry(storeIndex: 2, recommendations: recommendationsA, hoursAgo: 24 * 8 - 2)
        ]),
        weeklyOrder(daysAgo: 15, targetDaysAhead: -8, entries: [
            storeEntry(storeIndex: 1, recommendations: recommendationsB, hoursAgo: 24 * 15),
            storeEntry(storeIndex: 0, recommendations: recommendationsA, hoursAgo: 24 * 15 - 3)
        ]),
        weeklyOrder(daysAgo: 22, targetDaysAhead: -15, entries: [
            storeEntry(storeIndex: 2, recommendations: recommendationsC, hoursAgo: 24 * 22)
        ]),
        weeklyOrder(daysAgo: 29, targetDaysAhead: -22, entries: [
            storeEntry(storeIndex: 0, recommendations: recommendationsB, hoursAgo: 24 * 29),
            storeEntry(storeIndex: 1, recommendations: recommendationsC, hoursAgo: 24 * 29 - 2)
        ])
    ]

    private static let recommendationsA: [Recommendation] = [
        Recommendation(id: UUID(), product: MockProducts.panBlanco, suggestedQuantity: 14, editableQuantity: 14, reason: "Hueco y se agota cada 5 días.", confidence: 0.95, status: .accepted),
        Recommendation(id: UUID(), product: MockProducts.gansito, suggestedQuantity: 10, editableQuantity: 10, reason: "Quincena viernes.", confidence: 0.88, status: .accepted),
        Recommendation(id: UUID(), product: MockProducts.donas, suggestedQuantity: 4, editableQuantity: 4, reason: "Vence pronto, rotar al frente.", confidence: 0.75, status: .accepted)
    ]

    private static let recommendationsB: [Recommendation] = [
        Recommendation(id: UUID(), product: MockProducts.frituras, suggestedQuantity: 12, editableQuantity: 12, reason: "Partido hoy y alta rotación.", confidence: 0.92, status: .accepted),
        Recommendation(id: UUID(), product: MockProducts.papas, suggestedQuantity: 8, editableQuantity: 8, reason: "Partido hoy.", confidence: 0.86, status: .accepted),
        Recommendation(id: UUID(), product: MockProducts.panBlanco, suggestedQuantity: 16, editableQuantity: 16, reason: "Alta rotación en pan de caja.", confidence: 0.9, status: .accepted)
    ]

    private static let recommendationsC: [Recommendation] = [
        Recommendation(id: UUID(), product: MockProducts.gansito, suggestedQuantity: 12, editableQuantity: 12, reason: "Pastelitos suben por quincena.", confidence: 0.84, status: .accepted),
        Recommendation(id: UUID(), product: MockProducts.donas, suggestedQuantity: 6, editableQuantity: 6, reason: "Pan dulce con baja merma esta semana.", confidence: 0.8, status: .accepted),
        Recommendation(id: UUID(), product: MockProducts.papas, suggestedQuantity: 10, editableQuantity: 10, reason: "Reposición preventiva para fin de semana.", confidence: 0.78, status: .accepted)
    ]

    private static func weeklyOrder(daysAgo: Int, targetDaysAhead: Int, entries: [WeeklyOrderStoreEntry]) -> WeeklyOrder {
        WeeklyOrder(
            id: UUID(),
            routeName: "Ruta 14",
            createdAt: Date().addingTimeInterval(TimeInterval(-86_400 * daysAgo)),
            targetWeekStartDate: Calendar.current.date(byAdding: .day, value: targetDaysAhead, to: Date()) ?? Date(),
            finalizedAt: Date().addingTimeInterval(TimeInterval(-86_400 * daysAgo + 3_600)),
            entries: entries,
            status: .readyForNextWeek
        )
    }

    private static func storeEntry(
        storeIndex: Int,
        recommendations: [Recommendation],
        hoursAgo: Int
    ) -> WeeklyOrderStoreEntry {
        WeeklyOrderStoreEntry(
            id: UUID(),
            store: MockStores.allStores[storeIndex],
            recommendations: recommendations,
            totalPieces: recommendations.reduce(0) { $0 + $1.editableQuantity },
            avoidedWasteMXN: Double(recommendations.count * 42),
            addedAt: Date().addingTimeInterval(TimeInterval(-3_600 * hoursAgo))
        )
    }
}

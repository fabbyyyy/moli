import Foundation

struct MockStores {
    static let elPino = Store(
        id: UUID(),
        name: "Abarrotes El Pino",
        customerNumber: "1042",
        segment: "Canal detalle",
        routeName: "Ruta 14",
        address: "Dr. Andrade 12",
        visitStatus: .pending,
        pendingAlerts: 2,
        averageReturns: 2,
        trendPercentage: 12.0,
        lastVisitDaysAgo: 7,
        lastOrderPieces: 24,
        distanceKm: 1.2,
        estimatedMinutes: 4,
        latitude: 19.4219,
        longitude: -99.1429,
        coordinatesMockX: 0.3,
        coordinatesMockY: 0.6
    )
    
    static let elSol = Store(
        id: UUID(),
        name: "Tiendita El Sol",
        customerNumber: "2088",
        segment: "Tienda tradicional",
        routeName: "Ruta 14",
        address: "Av. Siempre Viva 123",
        visitStatus: .pending,
        pendingAlerts: 0,
        averageReturns: 1,
        trendPercentage: 8.0,
        lastVisitDaysAgo: 2,
        lastOrderPieces: 28,
        distanceKm: 2.5,
        estimatedMinutes: 8,
        latitude: 19.4285,
        longitude: -99.1340,
        coordinatesMockX: 0.5,
        coordinatesMockY: 0.4
    )
    
    static let guadalupe = Store(
        id: UUID(),
        name: "Mini Súper Guadalupe",
        customerNumber: "3185",
        segment: "Conveniencia",
        routeName: "Ruta 14",
        address: "Blvd. Revolución 44",
        visitStatus: .pending,
        pendingAlerts: 1,
        averageReturns: 3,
        trendPercentage: 6.0,
        lastVisitDaysAgo: 4,
        lastOrderPieces: 36,
        distanceKm: 4.1,
        estimatedMinutes: 12,
        latitude: 19.4360,
        longitude: -99.1230,
        coordinatesMockX: 0.7,
        coordinatesMockY: 0.2
    )
    
    static let allStores: [Store] = [elPino, elSol, guadalupe]
}

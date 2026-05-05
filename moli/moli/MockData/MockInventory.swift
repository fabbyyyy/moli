import Foundation

struct MockInventory {
    static func getInventory(for storeId: UUID) -> [InventoryItem] {
        return [
            InventoryItem(id: UUID(), storeId: storeId, product: MockProducts.panBlanco, currentQuantity: 5, expirationDate: Date().addingTimeInterval(86400 * 5), unitsToRemove: 0, shelfCapacity: 20),
            InventoryItem(id: UUID(), storeId: storeId, product: MockProducts.gansito, currentQuantity: 2, expirationDate: Date().addingTimeInterval(86400 * 10), unitsToRemove: 0, shelfCapacity: 15),
            InventoryItem(id: UUID(), storeId: storeId, product: MockProducts.donas, currentQuantity: 3, expirationDate: Date().addingTimeInterval(-86400 * 1), unitsToRemove: 2, shelfCapacity: 10), // 2 expired
            InventoryItem(id: UUID(), storeId: storeId, product: MockProducts.frituras, currentQuantity: 8, expirationDate: Date().addingTimeInterval(86400 * 20), unitsToRemove: 0, shelfCapacity: 12)
        ]
    }
}

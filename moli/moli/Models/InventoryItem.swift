import Foundation

struct InventoryItem: Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let product: Product
    var currentQuantity: Int
    var expirationDate: Date?
    var lotNumber: String?
    var unitsToRemove: Int
    let shelfCapacity: Int
}

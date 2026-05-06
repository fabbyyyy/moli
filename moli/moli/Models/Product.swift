import Foundation

struct Product: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let category: String
    let sku: String
    let shelfLifeDays: Int
    let brand: String
    let imageName: String?
    let unitPriceMXN: Double
}

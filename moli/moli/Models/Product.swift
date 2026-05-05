import Foundation

struct Product: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let sku: String
    let shelfLifeDays: Int
    let brand: String
    let imageName: String?
}

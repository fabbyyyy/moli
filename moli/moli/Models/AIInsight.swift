import Foundation

enum InsightType: String, Hashable {
    case expired
    case gap
    case expiringSoon
    case trend
    case rotation
    case warning
}

enum InsightSeverity: String, Hashable {
    case high
    case medium
    case low
}

struct AIInsight: Identifiable, Hashable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let relatedProductName: String?
}

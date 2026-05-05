import Foundation

struct CoachInstruction: Identifiable, Hashable {
    let id: UUID
    let stepNumber: Int
    let totalSteps: Int
    let title: String
    let instruction: String
    let impactText: String
    var isCompleted: Bool
}

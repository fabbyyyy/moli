import Foundation

class MockFoundationModelAIService: AIAnalysisProviding {
    func analyzeShelf(storeId: UUID, imagePath: String?) async throws -> [AIInsight] {
        // Fallback mock para demo en simulador o dispositivo sin disponibilidad del modelo.
        // No se usa internet para el análisis.
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate processing time
        
        return [
            // Historial
            AIInsight(id: UUID(), type: .rotation, title: "Gansito se agota cada 5 días aquí", description: "La rotación es alta.", severity: .medium, relatedProductName: "Gansito"),
            AIInsight(id: UUID(), type: .trend, title: "Frituras Picantes rotan 2× más rápido", description: "Promedio superior a tu ruta.", severity: .medium, relatedProductName: "Frituras Picantes"),
            AIInsight(id: UUID(), type: .trend, title: "Polvorones tienen baja rotación", description: "No traer más de 4 piezas, se quedan en anaquel.", severity: .low, relatedProductName: "Polvorones"),
            // Contexto
            AIInsight(id: UUID(), type: .warning, title: "Día del Trabajo hoy", description: "Pico de venta en botanas y refrescos, surtir al máximo.", severity: .high, relatedProductName: nil),
            AIInsight(id: UUID(), type: .warning, title: "Partido Selección esta noche", description: "Frituras y papas +40%, lleva extra.", severity: .high, relatedProductName: "Frituras Picantes")
        ]
    }
    
    func generateRecommendation(storeId: UUID, insights: [AIInsight]) async throws -> [Recommendation] {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        var recs: [Recommendation] = []

        // ── Huecos detectados en anaquel → resurtir Takis ──────────────
        if let gap = insights.first(where: { $0.type == .gap && $0.severity == .high }),
           let numStr = gap.description.components(separatedBy: " ").first(where: { Int($0) != nil }),
           let cantidad = Int(numStr), cantidad > 0 {
            recs.append(Recommendation(id: UUID(), product: MockProducts.takis,
                suggestedQuantity: cantidad, editableQuantity: cantidad,
                reason: "Anaquel con \(cantidad) huecos detectados.", confidence: 0.95, status: .pending))
        }

        // ── Partido Selección → más frituras y papas ───────────────────
        let hayPartido = insights.contains { $0.type == .warning && $0.title.lowercased().contains("partido") }
        if hayPartido {
            recs.append(Recommendation(id: UUID(), product: MockProducts.frituras,
                suggestedQuantity: 12, editableQuantity: 12,
                reason: "Partido Selección esta noche, alta demanda de botanas.", confidence: 0.92, status: .pending))
            recs.append(Recommendation(id: UUID(), product: MockProducts.papas,
                suggestedQuantity: 8, editableQuantity: 8,
                reason: "Partido esta noche, llevar extra.", confidence: 0.88, status: .pending))
        }

        // ── Día del Trabajo → botanas adicionales ──────────────────────
        let hayDiaTrabajo = insights.contains { $0.type == .warning && $0.title.lowercased().contains("trabajo") }
        if hayDiaTrabajo && !hayPartido {
            recs.append(Recommendation(id: UUID(), product: MockProducts.frituras,
                suggestedQuantity: 8, editableQuantity: 8,
                reason: "Día del Trabajo, pico en botanas.", confidence: 0.85, status: .pending))
        }

        // ── Alta rotación de Gansito ───────────────────────────────────
        if insights.contains(where: { $0.relatedProductName == "Gansito" && $0.type == .rotation }) {
            recs.append(Recommendation(id: UUID(), product: MockProducts.gansito,
                suggestedQuantity: 10, editableQuantity: 10,
                reason: "Se agota cada 5 días, rotación alta.", confidence: 0.87, status: .pending))
        }

        // ── Polvorones baja rotación → máximo 4 ───────────────────────
        if insights.contains(where: { $0.relatedProductName == "Polvorones" }) {
            recs.append(Recommendation(id: UUID(), product: MockProducts.polvorones,
                suggestedQuantity: 4, editableQuantity: 4,
                reason: "Baja rotación, no exceder 4 piezas.", confidence: 0.78, status: .pending))
        }

        return recs
    }
    
    func generateCoachInstructions(storeId: UUID) async throws -> [CoachInstruction] {
        return [
            CoachInstruction(id: UUID(), stepNumber: 1, totalSteps: 4, title: "Retirar Merma", instruction: "Saca las 2 Donas Glaseadas vencidas.", impactText: "Merma evitada visita +$48", isCompleted: false),
            CoachInstruction(id: UUID(), stepNumber: 2, totalSteps: 4, title: "Reponer", instruction: "Llena los 3 huecos del nivel 1 con Pan Blanco y Gansito. Coloca el lote nuevo detrás del existente.", impactText: "Asegura venta", isCompleted: false)
        ]
    }
}

import Foundation

class MockFoundationModelAIService: AIAnalysisProviding {
    func analyzeShelf(storeId: UUID, imagePath: String?) async throws -> [AIInsight] {
        // Fallback mock para demo en simulador o dispositivo sin disponibilidad del modelo.
        // No se usa internet para el análisis.
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate processing time
        
        return [
            AIInsight(id: UUID(), type: .expired, title: "2 piezas de Donas Glaseadas vencidas", description: "Retíralas de inmediato.", severity: .high, relatedProductName: "Donas Glaseadas"),
            AIInsight(id: UUID(), type: .gap, title: "3 huecos vacíos", description: "Falta Pan Blanco, Gansito, Frituras.", severity: .medium, relatedProductName: nil),
            AIInsight(id: UUID(), type: .expiringSoon, title: "1 Donas Glaseadas se vence en 4 días", description: "Pásalas al frente para que roten.", severity: .low, relatedProductName: "Donas Glaseadas"),
            AIInsight(id: UUID(), type: .rotation, title: "Gansito se agota cada 5 días aquí", description: "La rotación es alta.", severity: .medium, relatedProductName: "Gansito"),
            AIInsight(id: UUID(), type: .trend, title: "Frituras Picantes rotan 2× más rápido", description: "Promedio superior a tu ruta.", severity: .medium, relatedProductName: "Frituras Picantes"),
            AIInsight(id: UUID(), type: .warning, title: "Quincena el viernes", description: "Pico de venta en pastelitos y snacks.", severity: .medium, relatedProductName: nil),
            AIInsight(id: UUID(), type: .warning, title: "Partido Selección esta noche", description: "Frituras +40%.", severity: .medium, relatedProductName: "Frituras Picantes"),
            AIInsight(id: UUID(), type: .warning, title: "Feria de San Marcos en 3 días", description: "Zona de alta afluencia, surtir al máximo.", severity: .medium, relatedProductName: nil),
            AIInsight(id: UUID(), type: .warning, title: "Día de Muertos en 5 días", description: "Pico histórico en pan dulce y pastelitos.", severity: .medium, relatedProductName: "Donas Glaseadas")
        ]
    }
    
    func generateRecommendation(storeId: UUID, insights: [AIInsight]) async throws -> [Recommendation] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            Recommendation(id: UUID(), product: MockProducts.panBlanco, suggestedQuantity: 14, editableQuantity: 14, reason: "Hueco y se agota cada 5 días.", confidence: 0.95, status: .pending),
            Recommendation(id: UUID(), product: MockProducts.gansito, suggestedQuantity: 10, editableQuantity: 10, reason: "Quincena viernes.", confidence: 0.88, status: .pending),
            Recommendation(id: UUID(), product: MockProducts.frituras, suggestedQuantity: 12, editableQuantity: 12, reason: "Partido hoy y alta rotación.", confidence: 0.92, status: .pending),
            Recommendation(id: UUID(), product: MockProducts.donas, suggestedQuantity: 4, editableQuantity: 4, reason: "Vence pronto, rotar al frente.", confidence: 0.75, status: .pending),
            Recommendation(id: UUID(), product: MockProducts.papas, suggestedQuantity: 8, editableQuantity: 8, reason: "Partido hoy.", confidence: 0.86, status: .pending)
        ]
    }
    
    func generateCoachInstructions(storeId: UUID) async throws -> [CoachInstruction] {
        return [
            CoachInstruction(id: UUID(), stepNumber: 1, totalSteps: 4, title: "Retirar Merma", instruction: "Saca las 2 Donas Glaseadas vencidas.", impactText: "Merma evitada visita +$48", isCompleted: false),
            CoachInstruction(id: UUID(), stepNumber: 2, totalSteps: 4, title: "Reponer", instruction: "Llena los 3 huecos del nivel 1 con Pan Blanco y Gansito. Coloca el lote nuevo detrás del existente.", impactText: "Asegura venta", isCompleted: false)
        ]
    }
}

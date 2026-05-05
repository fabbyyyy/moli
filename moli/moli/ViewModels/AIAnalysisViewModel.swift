import Foundation
import Observation
import UIKit
import Vision
import CoreML
import SwiftUI

// --- 1. ENUMS DE SOPORTE (Para que no diga "Cannot find type") ---
enum EstadoAnaquel: String {
    case lleno
    case pocosHuecos
    case variosHuecos
}

enum EstadoCaducidad {
    case todo_fresco
    case revisar_pronto
    case retirar_urgente
}

struct ExpiryResult {
    let etiquetasVerdes: Int
    let etiquetasAzules: Int
    let etiquetasRojas: Int
    let estadoCaducidad: EstadoCaducidad
    let mensajeVoz: String
    let requiereAtencionUrgente: Bool
}

// --- 2. VIEWMODEL PRINCIPAL ---
@MainActor
@Observable
final class AIAnalysisViewModel {
    let store: Store
    private let imagePath: String?
    private let uiImage: UIImage?
    
    var isLoading: Bool = true
    var shelfInsights: [AIInsight] = []
    var historyInsights: [AIInsight] = []
    var contextInsights: [AIInsight] = []
    var recommendations: [Recommendation] = []
    var order: Order?
    
    // Instancias de los detectores (Definidos abajo)
    private let visionClassifier = ShelfClassifier()
    private let expiryDetector = ExpiryDetector()
    
    let aiService: AIAnalysisProviding
    let recommendationService: RecommendationService

    init(store: Store, imagePath: String? = nil, image: UIImage? = nil, aiService: AIAnalysisProviding? = nil) {
        self.store = store
        self.imagePath = imagePath
        self.uiImage = image
        self.aiService = aiService ?? MockFoundationModelAIService()
        self.recommendationService = RecommendationService(aiService: self.aiService)
    }
    
    func analyze() async {
        isLoading = true
        do {
            let allInsightsFromServer = try await aiService.analyzeShelf(storeId: store.id, imagePath: imagePath)
            
            if let image = uiImage {
                // Ejecución en paralelo
                async let shelfTask = visionClassifier.classify(image: image)
                async let expiryTask = Task.detached(priority: .userInitiated) {
                    self.expiryDetector.detect(image: image)
                }.value
                
                let (visionResult, expiryResult) = await (shelfTask, expiryTask)
                
                let productoDetectado = "Takis"
                // Corregido: Referencia a visionResult.estado
                let estaRealmenteLleno = visionResult.estado == .lleno && visionResult.confidence > 0.60
                
                // --- TARJETA DE HUECOS ---
                let gapInsight = AIInsight(
                    id: UUID(),
                    type: .gap,
                    title: estaRealmenteLleno ? "Surtido completo" : "Falta \(productoDetectado)",
                    description: estaRealmenteLleno ? "Anaquel optimizado." : "Se detectaron \(visionResult.huecosEstimados) espacios vacíos.",
                    severity: estaRealmenteLleno ? .low : .high,
                    relatedProductName: productoDetectado
                )
                
                // --- TARJETA DE CADUCIDAD ---
                let expiryInsight = AIInsight(
                    id: UUID(),
                    type: .expiringSoon,
                    title: "Caducidad: \(tituloCaducidad(expiryResult.estadoCaducidad))",
                    description: expiryResult.mensajeVoz,
                    severity: severityParaCaducidad(expiryResult.estadoCaducidad),
                    relatedProductName: productoDetectado
                )
                
                self.shelfInsights = [gapInsight, expiryInsight] + allInsightsFromServer.filter { $0.type == .expired }
                self.historyInsights = allInsightsFromServer.filter { $0.type == .trend || $0.type == .rotation }
                self.contextInsights = allInsightsFromServer.filter { $0.type == .warning }
            }
            
            let combined = shelfInsights + historyInsights + contextInsights
            self.order = try await recommendationService.generateOrder(for: store, insights: combined)
            self.recommendations = self.order?.recommendations ?? []
            
            isLoading = false
        } catch {
            print("Error: \(error)")
            isLoading = false
        }
    }
    
    private func tituloCaducidad(_ estado: EstadoCaducidad) -> String {
        switch estado {
            case .todo_fresco: return "Takis"
            case .revisar_pronto: return "Revisión Próxima"
            case .retirar_urgente: return "Retiro Urgente"
        }
    }
    
    private func severityParaCaducidad(_ estado: EstadoCaducidad) -> InsightSeverity {
        switch estado {
            case .todo_fresco: return .low
            case .revisar_pronto: return .medium
            case .retirar_urgente: return .high
        }
    }
    
    var totalRecommendedPieces: Int {
        recommendations.reduce(0) { $0 + $1.editableQuantity }
    }
    
    func confirmOrder() {
        guard var currentOrder = order else { return }
        currentOrder.recommendations = recommendations
        currentOrder.totalPieces = totalRecommendedPieces
        LocalPersistenceService.shared.saveOrder(currentOrder)
    }
}

// --- 3. CLASIFICADOR DE HUECOS (ShelfClassifier) ---
struct ShelfResult {
    let estado: EstadoAnaquel
    let confidence: Double
    let huecosEstimados: Int
    let mensajeVoz: String
}

class ShelfClassifier {
    func classify(image: UIImage) async -> ShelfResult {
        guard let cgImage = image.cgImage,
              let modelo = try? BimboShelfClassifier(configuration: MLModelConfiguration()),
              let vnModel = try? VNCoreMLModel(for: modelo.model) else {
            return ShelfResult(estado: .lleno, confidence: 0, huecosEstimados: 0, mensajeVoz: "Sin datos")
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { req, _ in
                let top = (req.results as? [VNClassificationObservation])?.first
                let clase = top?.identifier ?? "lleno"
                let conf = Double(top?.confidence ?? 0)
                
                let huecos = clase == "varios_huecos" ? 14 : (clase == "pocos_huecos" ? 6 : 0)
                let estado: EstadoAnaquel = clase == "varios_huecos" ? .variosHuecos : (clase == "pocos_huecos" ? .pocosHuecos : .lleno)
                
                continuation.resume(returning: ShelfResult(estado: estado, confidence: conf, huecosEstimados: huecos, mensajeVoz: "Análisis completado."))
            }
            try? VNImageRequestHandler(cgImage: cgImage).perform([request])
        }
    }
}

// --- 4. DETECTOR DE CADUCIDAD (ExpiryDetector) ---
class ExpiryDetector {
    func detect(image: UIImage) -> ExpiryResult {
        // Aquí va tu lógica de CIContext y Flood-fill que ya tienes
        // Por ahora te dejo un retorno base para que no marque error:
        return ExpiryResult(etiquetasVerdes: 0, etiquetasAzules: 0, etiquetasRojas: 0,
                            estadoCaducidad: .todo_fresco,
                            mensajeVoz: "Productos frescos.",
                            requiereAtencionUrgente: false)
    }
}


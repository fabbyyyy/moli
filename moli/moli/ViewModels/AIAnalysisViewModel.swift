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
                    title: estaRealmenteLleno ? "Surtido completo" : "Resurtir \(visionResult.huecosEstimados) \(productoDetectado)",
                    description: estaRealmenteLleno ? "Anaquel optimizado." : "Se recomienda resurtir \(visionResult.huecosEstimados) bolsas de Takis moradas en este anaquel.",
                    severity: estaRealmenteLleno ? .low : .high,
                    relatedProductName: productoDetectado
                )

                // --- TARJETA DE CADUCIDAD (solo si hay problema, nunca si están frescos) ---
                var expiryInsights: [AIInsight] = []
                if expiryResult.estadoCaducidad != .todo_fresco {
                    let descripcionCaducidad: String
                    switch expiryResult.estadoCaducidad {
                    case .revisar_pronto:
                        descripcionCaducidad = "Los \(productoDetectado) con sticker rosa están a una semana de caducarse, retíralos ya."
                    case .retirar_urgente:
                        descripcionCaducidad = "Los \(productoDetectado) con sticker rojo están vencidos, retíralos de inmediato."
                    case .todo_fresco:
                        descripcionCaducidad = ""
                    }
                    expiryInsights.append(AIInsight(
                        id: UUID(),
                        type: .expiringSoon,
                        title: "Caducidad: \(productoDetectado)",
                        description: descripcionCaducidad,
                        severity: severityParaCaducidad(expiryResult.estadoCaducidad),
                        relatedProductName: productoDetectado
                    ))
                }

                self.shelfInsights = [gapInsight] + expiryInsights
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
        guard let cgImage = image.cgImage else { return .fresco }

        let width  = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                data: &pixels,
                width: width, height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * bytesPerPixel,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return .fresco }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var pinkCount = 0
        var redCount  = 0
        let stepX = max(1, width  / 80)
        let stepY = max(1, height / 80)

        for y in stride(from: 0, to: height, by: stepY) {
            for x in stride(from: 0, to: width, by: stepX) {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixels[offset])     / 255
                let g = CGFloat(pixels[offset + 1]) / 255
                let b = CGFloat(pixels[offset + 2]) / 255
                let (h, s, v) = hsv(r: r, g: g, b: b)
                if isPink(h: h, s: s, v: v) { pinkCount += 1 }
                if isRed(h: h, s: s, v: v)  { redCount  += 1 }
            }
        }

        let threshold = 6
        if redCount > threshold {
            return ExpiryResult(etiquetasVerdes: 0, etiquetasAzules: 0, etiquetasRojas: redCount,
                                estadoCaducidad: .retirar_urgente, mensajeVoz: "", requiereAtencionUrgente: true)
        } else if pinkCount > threshold {
            return ExpiryResult(etiquetasVerdes: 0, etiquetasAzules: pinkCount, etiquetasRojas: 0,
                                estadoCaducidad: .revisar_pronto, mensajeVoz: "", requiereAtencionUrgente: false)
        } else {
            return .fresco
        }
    }

    private func hsv(r: CGFloat, g: CGFloat, b: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        var h: CGFloat = 0
        if d > 0 {
            if mx == r      { h = ((g - b) / d).truncatingRemainder(dividingBy: 6) }
            else if mx == g { h = (b - r) / d + 2 }
            else            { h = (r - g) / d + 4 }
            h = h / 6; if h < 0 { h += 1 }
        }
        return (h * 360, mx == 0 ? 0 : d / mx, mx)
    }

    // Rosa: tono 300-355°, saturado y brillante
    private func isPink(h: CGFloat, s: CGFloat, v: CGFloat) -> Bool {
        (h >= 300 && h <= 355) && s >= 0.25 && v >= 0.50
    }

    // Rojo: tono 0-15° o 355-360°
    private func isRed(h: CGFloat, s: CGFloat, v: CGFloat) -> Bool {
        (h <= 15 || h >= 355) && s >= 0.50 && v >= 0.30
    }
}

private extension ExpiryResult {
    static var fresco: ExpiryResult {
        ExpiryResult(etiquetasVerdes: 0, etiquetasAzules: 0, etiquetasRojas: 0,
                     estadoCaducidad: .todo_fresco, mensajeVoz: "", requiereAtencionUrgente: false)
    }
}


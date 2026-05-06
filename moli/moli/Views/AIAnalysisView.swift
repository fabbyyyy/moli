import SwiftUI
import AVFoundation

struct AIAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AIAnalysisViewModel
    @State private var navigateToConfirmation = false
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var isSpeaking = false
    let manosLibres: Bool

    init(store: Store, imagePath: String? = nil, images: [UIImage] = [], manosLibres: Bool = false) {
        _viewModel = State(initialValue: AIAnalysisViewModel(store: store, imagePath: imagePath, images: images))
        self.manosLibres = manosLibres
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundGray.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AnalysisReadyHeader(storeName: viewModel.store.name)

                    // --- SECCIONES POR ANAQUEL ---
                    ForEach(viewModel.shelfResults) { result in
                        InsightSection(
                            label: "ANAQUEL \(result.shelfNumber)",
                            title: "Análisis de Imagen",
                            insights: result.insights,
                            speechButton: (manosLibres && result.shelfNumber == 1) ? AnyView(
                                Button(action: toggleSpeech) {
                                    Image(systemName: isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(isSpeaking ? .red : AppTheme.Colors.primaryBlue)
                                }
                            ) : nil
                        )
                    }

                    // --- SECCIÓN B: HISTORIAL ---
                    if !viewModel.historyInsights.isEmpty {
                        InsightSection(label: "B · HISTORIAL", title: "Tendencias de venta", insights: viewModel.historyInsights)
                    }

                    // --- SECCIÓN C: CONTEXTO ---
                    if !viewModel.contextInsights.isEmpty {
                        InsightSection(label: "C · CONTEXTO", title: "Eventos actuales", insights: viewModel.contextInsights)
                    }

                    // --- SECCIÓN D: PEDIDO ---
                    RecommendationSection(recommendations: $viewModel.recommendations, totalPieces: viewModel.totalRecommendedPieces)
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal)
            }
            .disabled(viewModel.isLoading)

            if !viewModel.isLoading {
                AnalysisBottomBar(totalPieces: viewModel.totalRecommendedPieces, confirmAction: confirmOrder)
            }

        }
        .overlay { if viewModel.isLoading { AnalysisLoadingView() } }
        .navigationDestination(isPresented: $navigateToConfirmation) {
            if let order = viewModel.order {
                ConfirmationView(store: viewModel.store, pieces: order.totalPieces, wasteAvoided: order.avoidedWasteMXN)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .task { await viewModel.analyze() }
        .onChange(of: viewModel.isLoading) { _, loading in
            if !loading && manosLibres { speakAnalysis() }
        }
        .onDisappear { synthesizer.stopSpeaking(at: .immediate); isSpeaking = false }
    }

    private func toggleSpeech() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        } else {
            speakAnalysis()
        }
    }

    private func speakAnalysis() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = true

        var partes: [String] = ["Análisis completado. \(viewModel.store.name)."]

        for result in viewModel.shelfResults {
            partes.append("Anaquel \(result.shelfNumber).")
            for i in result.insights {
                partes.append("\(i.title). \(i.description)")
            }
        }
        if !viewModel.historyInsights.isEmpty {
            partes.append("Tendencias de venta.")
            for i in viewModel.historyInsights {
                partes.append("\(i.title). \(i.description)")
            }
        }
        if !viewModel.contextInsights.isEmpty {
            partes.append("Eventos actuales.")
            for i in viewModel.contextInsights {
                partes.append("\(i.title). \(i.description)")
            }
        }
        if !viewModel.recommendations.isEmpty {
            partes.append("Pedido sugerido: \(viewModel.totalRecommendedPieces) piezas.")
            for r in viewModel.recommendations {
                partes.append("\(r.editableQuantity) \(r.product.name).")
            }
        }

        let texto = partes.joined(separator: " ")
        let utterance = AVSpeechUtterance(string: texto)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.0
        let delegate = SpeechDelegate { isSpeaking = false }
        synthesizer.delegate = delegate
        objc_setAssociatedObject(synthesizer, &AssociatedKeys.delegate, delegate, .OBJC_ASSOCIATION_RETAIN)
        synthesizer.speak(utterance)
    }

    private func confirmOrder() {
        viewModel.confirmOrder()
        navigateToConfirmation = viewModel.order != nil
    }
}

private enum AssociatedKeys { static var delegate = 0 }

private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onFinish() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onFinish() }
    }
}

// MARK: - COMPONENTE DE TARJETAS (INSIGHTS)
private struct InsightSection: View {
    let label: String
    let title: String
    let insights: [AIInsight]
    var speechButton: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                SectionTitle(label: label, title: title)
                Spacer()
                if let btn = speechButton { btn }
            }
            
            ForEach(insights, id: \.id) { insight in
                HStack(spacing: 0) {
                    // Semáforo lateral
                    Rectangle()
                        .fill(colorFor(insight.severity))
                        .frame(width: 6)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(insight.description)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.mutedGray)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // Icono descriptivo según el tipo de insight
                    Image(systemName: iconFor(insight.type))
                        .font(.system(size: 18))
                        .foregroundColor(colorFor(insight.severity).opacity(0.8))
                        .padding(.trailing, 16)
                }
                .background(AppTheme.Colors.cardWhite)
                .cornerRadius(AppTheme.Radii.medium)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }

    private func colorFor(_ severity: InsightSeverity) -> Color {
        switch severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    private func iconFor(_ type: InsightType) -> String {
        switch type {
        case .gap: return "square.grid.3x1.below.line.grid.1x2"
        case .expiringSoon: return "calendar.badge.exclamationmark"
        case .expired: return "exclamationmark.octagon"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .rotation: return "arrow.2.squarepath"
        case .warning: return "exclamationmark.triangle"
        }
    }
}

// MARK: - COMPONENTES DE APOYO
private struct SectionTitle: View {
    let label: String; let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).bold().foregroundColor(AppTheme.Colors.primaryBlue)
            Text(title).font(.title3).bold().foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

private struct AnalysisReadyHeader: View {
    let storeName: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ANÁLISIS COMPLETADO").font(.caption).bold().foregroundColor(AppTheme.Colors.textPrimary)
            Text(storeName).font(.largeTitle).bold().foregroundColor(AppTheme.Colors.primaryBlue)
        }.padding(.top)
    }
}

private struct RecommendationSection: View {
    @Binding var recommendations: [Recommendation]
    let totalPieces: Int

    var totalMXN: Double {
        recommendations.reduce(0) { $0 + Double($1.editableQuantity) * $1.product.unitPriceMXN }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(label: "D · PEDIDO", title: "Sugerencia: \(totalPieces) pzas")
            ForEach($recommendations) { $rec in
                ProductRecommendationCard(recommendation: $rec)
            }
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TOTAL DEL PEDIDO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    Text("$\(totalMXN, specifier: "%.2f") MXN")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(AppTheme.Colors.primaryBlue)
                }
                .padding()
                .background(AppTheme.Colors.cardWhite)
                .cornerRadius(AppTheme.Radii.medium)
            }
        }
    }
}

private struct AnalysisBottomBar: View {
    let totalPieces: Int; let confirmAction: () -> Void
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 100)
                    .blur(radius: 10)
                    .offset(y: 20)
                
                Button(action: confirmAction) {
                    Text("CONFIRMAR · \(totalPieces) pzas")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(AppTheme.Colors.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

private struct AnalysisLoadingView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundGray.ignoresSafeArea()
            VStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Analizando anaquel...")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
    }
}


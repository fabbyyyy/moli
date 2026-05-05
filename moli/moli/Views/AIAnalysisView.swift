import SwiftUI

struct AIAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AIAnalysisViewModel
    @State private var navigateToConfirmation = false

    init(store: Store, imagePath: String? = nil) {
        _viewModel = State(initialValue: AIAnalysisViewModel(store: store, imagePath: imagePath))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundGray.ignoresSafeArea()

            AnalysisContent(
                storeName: viewModel.store.name,
                shelfInsights: viewModel.shelfInsights,
                historyInsights: viewModel.historyInsights,
                contextInsights: viewModel.contextInsights,
                recommendations: $viewModel.recommendations,
                totalRecommendedPieces: viewModel.totalRecommendedPieces
            )
            .disabled(viewModel.isLoading)

            if !viewModel.isLoading {
                AnalysisBottomBar(
                    totalPieces: viewModel.totalRecommendedPieces,
                    confirmAction: confirmOrder
                )
            }
        }
        .overlay {
            if viewModel.isLoading {
                AnalysisLoadingView()
            }
        }
        .navigationTitle("Análisis del anaquel")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: dismissView) {
                    Image(systemName: "chevron.left")
                }
                .tint(AppTheme.Colors.textPrimary)
            }
        }
        .navigationDestination(isPresented: $navigateToConfirmation) {
            if let order = viewModel.order {
                ConfirmationView(
                    store: viewModel.store,
                    pieces: order.totalPieces,
                    wasteAvoided: order.avoidedWasteMXN
                )
            }
        }
        .task {
            await analyzeShelf()
        }
    }

    private func dismissView() {
        dismiss()
    }

    private func analyzeShelf() async {
        await viewModel.analyze()
    }

    private func confirmOrder() {
        viewModel.confirmOrder()
        navigateToConfirmation = viewModel.order != nil
    }
}

private struct AnalysisContent: View {
    let storeName: String
    let shelfInsights: [AIInsight]
    let historyInsights: [AIInsight]
    let contextInsights: [AIInsight]
    @Binding var recommendations: [Recommendation]
    let totalRecommendedPieces: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AnalysisReadyHeader(storeName: storeName)

                InsightSection(
                    label: "A · LO QUE VI EN EL ANAQUEL",
                    title: "\(shelfInsights.count) cosas que vi en tu foto",
                    insights: shelfInsights
                )

                InsightSection(
                    label: "B · LO QUE ME DICE EL HISTORIAL",
                    title: "Cómo se mueve esta tienda",
                    insights: historyInsights
                )

                InsightSection(
                    label: "C · EVENTOS Y CONTEXTO",
                    title: "Qué está pasando esta semana",
                    insights: contextInsights
                )

                RecommendationSection(
                    recommendations: $recommendations,
                    totalPieces: totalRecommendedPieces
                )

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
}

private struct AnalysisReadyHeader: View {
    let storeName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                Text("ANÁLISIS LISTO EN 6 SEG")
            }
            .font(.caption)
            .fontWeight(.bold)
            .textCase(.uppercase)
            .foregroundColor(AppTheme.Colors.textPrimary)

            Text(storeName)
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(AppTheme.Colors.primaryBlue)
        }
    }
}

private struct InsightSection: View {
    let label: String
    let title: String
    let insights: [AIInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(label: label, title: title)

            ForEach(insights) { insight in
                InsightCard(insight: insight)
            }
        }
    }
}

private struct RecommendationSection: View {
    @Binding var recommendations: [Recommendation]
    let totalPieces: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(
                label: "D · TE RECOMIENDO PEDIR ESTO",
                title: "Pedido sugerido · \(totalPieces) piezas"
            )

            ForEach($recommendations) { $recommendation in
                ProductRecommendationCard(recommendation: $recommendation)
            }
        }
    }
}

private struct SectionTitle: View {
    let label: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.primaryBlue)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.top, 10)
    }
}

private struct AnalysisBottomBar: View {
    let totalPieces: Int
    let confirmAction: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MicrophoneButton()

                    Button(action: confirmAction) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("CONFIRMAR · \(totalPieces) pzas")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.Colors.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.Radii.medium)
                    }
                }

                HStack {
                    Text("Toca el micrófono para confirmar por voz")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.yellow)
                        Text("Pantalla bloqueada")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.primaryBlue)
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundGray)
        }
    }
}

private struct MicrophoneButton: View {
    var body: some View {
        Button(action: startVoiceConfirmation) {
            Image(systemName: "mic")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .frame(width: 54, height: 54)
                .background(AppTheme.Colors.cardWhite)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.Colors.primaryBlue, lineWidth: 2))
        }
    }
    
    private func startVoiceConfirmation() {}
}

private struct AnalysisLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.Colors.primaryBlue)
            Text("Moli está analizando el anaquel...")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.primaryBlue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundGray)
    }
}

#Preview {
    AIAnalysisView(store: MockStores.elPino)
}

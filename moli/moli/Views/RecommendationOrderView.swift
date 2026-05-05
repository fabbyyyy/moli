import SwiftUI

struct RecommendationOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecommendationViewModel
    @State private var navigateToConfirmation = false

    init(store: Store, insights: [AIInsight]) {
        _viewModel = State(initialValue: RecommendationViewModel(store: store, allInsights: insights))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundGray.ignoresSafeArea()

            RecommendationOrderContent(
                storeName: viewModel.store.name,
                recommendations: $viewModel.recommendations,
                totalPieces: viewModel.totalPieces
            )
            .disabled(viewModel.isLoading)

            if !viewModel.isLoading {
                RecommendationOrderBottomBar(
                    totalPieces: viewModel.totalPieces,
                    sendAction: confirmOrder
                )
            }
        }
        .overlay {
            if viewModel.isLoading {
                RecommendationLoadingView()
            }
        }
        .navigationTitle("Recomendación de pedido")
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
            await loadRecommendations()
        }
    }

    private func dismissView() {
        dismiss()
    }

    private func loadRecommendations() async {
        await viewModel.loadRecommendations()
    }

    private func confirmOrder() {
        viewModel.confirmOrder()
        navigateToConfirmation = viewModel.order != nil
    }
}

private struct RecommendationOrderContent: View {
    let storeName: String
    @Binding var recommendations: [Recommendation]
    let totalPieces: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pedido para")
                        .font(.caption)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundColor(AppTheme.Colors.primaryBlue)

                    Text(storeName)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                RecommendationSummaryCard(totalPieces: totalPieces)

                Text("PRODUCTOS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .padding(.top, 10)

                ForEach($recommendations) { $recommendation in
                    ProductRecommendationCard(recommendation: $recommendation)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
}

private struct RecommendationSummaryCard: View {
    let totalPieces: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("PIEZAS SUGERIDAS")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                Text("\(totalPieces)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
            }
            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.softBlue)
        .cornerRadius(AppTheme.Radii.medium)
    }
}

private struct RecommendationOrderBottomBar: View {
    let totalPieces: Int
    let sendAction: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Button(action: sendAction) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("ENVIAR PEDIDO · \(totalPieces) pzas")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.Radii.medium)
            }
            .padding()
            .background(AppTheme.Colors.backgroundGray)
        }
    }
}

private struct RecommendationLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.Colors.primaryBlue)
            Text("Calculando recomendación perfecta...")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.primaryBlue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundGray)
    }
}

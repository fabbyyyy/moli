import SwiftUI

struct DailyOrdersView: View {
    @State private var viewModel = DailyOrdersViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundGray.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        DailyOrdersHeader()

                        LargeBlueMetricCard(
                            title: "MERMA EVITADA HOY",
                            value: "$\(Int(viewModel.totalWasteAvoided)) MXN",
                            subtitle: "La IA evitó mermas en \(viewModel.orders.count) tiendas"
                        )
                        .padding(.horizontal)

                        DailyOrdersMetricRow(orderCount: viewModel.orders.count)
                        QuincenaAlert()
                        CompletedOrdersSection(orders: viewModel.orders)

                        Spacer(minLength: 40)
                    }
                }
            }
            .task {
                loadOrders()
            }
        }
    }

    private func loadOrders() {
        viewModel.loadOrders()
    }
}

private struct DailyOrdersHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hoy · Ruta 14")
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(AppTheme.Colors.primaryBlue)

            Text("Pedidos del día")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

private struct DailyOrdersMetricRow: View {
    let orderCount: Int

    var body: some View {
        HStack(spacing: 16) {
            MetricCard(title: "TIENDAS", value: "\(orderCount)/8", icon: "storefront.fill")
            MetricCard(title: "TOTAL VENDIDO", value: "$\(orderCount * 450)", icon: "banknote.fill")
        }
        .padding(.horizontal)
    }
}

private struct QuincenaAlert: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .font(.title3)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Quincena mañana")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primaryBlue)

                Text("6 tiendas en zona de impacto · revisa tu surtido")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.primaryBlue.opacity(0.8))
            }
        }
        .padding()
        .background(AppTheme.Colors.softBlue)
        .cornerRadius(AppTheme.Radii.medium)
        .padding(.horizontal)
    }
}

private struct CompletedOrdersSection: View {
    let orders: [Order]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ÓRDENES COMPLETADAS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .padding(.top, 10)

            VStack(spacing: 12) {
                ForEach(orders) { order in
                    CompletedOrderRow(order: order)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct CompletedOrderRow: View {
    let order: Order

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.store.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                HStack {
                    Text(order.date, style: .time)
                    Text("·")
                    Text("\(order.totalPieces) piezas")
                }
                .font(.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
            }

            Spacer()

            Text("$\(order.totalPieces * 15)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 2)
    }
}

#Preview {
    DailyOrdersView()
}

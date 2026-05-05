import SwiftUI
import UIKit

struct DailyOrdersView: View {
    @State private var viewModel = DailyOrdersViewModel()
    @State private var showsAllHistory = false

    private var visibleHistoryOrders: [WeeklyOrder] {
        showsAllHistory ? viewModel.historyOrders : viewModel.recentHistoryOrders
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundGray.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        DailyOrdersHeader()

                        LargeBlueMetricCard(
                            title: "TOTAL DEL PEDIDO",
                            value: "\(viewModel.currentOrder?.totalPieces ?? 0) pzas",
                            subtitle: "\(viewModel.currentOrder?.storeCount ?? 0) tiendas para la siguiente semana"
                        )
                        .padding(.horizontal)

                        DailyOrdersMetricRow(
                            storeCount: viewModel.currentOrder?.storeCount ?? 0,
                            totalMXN: viewModel.currentOrder?.estimatedTotalMXN ?? 0
                        )

                        CurrentWeeklyOrderSection(
                            order: viewModel.currentOrder,
                            isPendingConfirmation: viewModel.currentOrderIsPendingConfirmation
                        )

                        OrderHistorySection(
                            orders: visibleHistoryOrders,
                            hasMoreOrders: viewModel.hasMoreHistoryOrders,
                            showsAllHistory: showsAllHistory,
                            toggleShowAllAction: toggleHistoryVisibility
                        )

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Pedidos")
            .navigationBarTitleDisplayMode(.large)
            .task {
                loadOrders()
            }
        }
    }

    private func loadOrders() {
        viewModel.loadOrders()
    }

    private func toggleHistoryVisibility() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showsAllHistory.toggle()
        }
    }
}

private struct DailyOrdersHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pedidos · Ruta 14")
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(AppTheme.Colors.primaryBlue)

            Text("Pedido semanal")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

private struct DailyOrdersMetricRow: View {
    let storeCount: Int
    let totalMXN: Double

    var body: some View {
        HStack(spacing: 16) {
            MetricCard(title: "TIENDAS", value: "\(storeCount)", icon: "storefront.fill")
            MetricCard(title: "TOTAL", value: totalMXN.currencyText, icon: "banknote.fill")
        }
        .padding(.horizontal)
    }
}

private struct CurrentWeeklyOrderSection: View {
    let order: WeeklyOrder?
    let isPendingConfirmation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OrdersSectionHeader(
                title: "Pedido actual",
                subtitle: isPendingConfirmation ? "Cargado desde la ruta activa" : "Confirmado para la siguiente semana"
            )

            if let order {
                NavigationLink {
                    WeeklyOrderDetailView(order: order)
                } label: {
                    WeeklyOrderSummaryCard(order: order, isCurrent: true)
                }
                .buttonStyle(.plain)
            } else {
                EmptyCurrentOrderCard()
            }
        }
        .padding(.horizontal)
    }
}

private struct OrderHistorySection: View {
    let orders: [WeeklyOrder]
    let hasMoreOrders: Bool
    let showsAllHistory: Bool
    let toggleShowAllAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OrdersSectionHeader(title: "Histórico", subtitle: "Últimos pedidos completados")

            if orders.isEmpty {
                Text("Todavía no hay pedidos anteriores.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.Colors.cardWhite)
                    .cornerRadius(AppTheme.Radii.medium)
            } else {
                VStack(spacing: 12) {
                    ForEach(orders) { order in
                        NavigationLink {
                            WeeklyOrderDetailView(order: order)
                        } label: {
                            WeeklyOrderSummaryCard(order: order, isCurrent: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if hasMoreOrders {
                Button(action: toggleShowAllAction) {
                    HStack {
                        Text(showsAllHistory ? "Ver menos" : "Ver más")
                        Image(systemName: showsAllHistory ? "chevron.up" : "chevron.down")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.softBlue)
                    .cornerRadius(AppTheme.Radii.medium)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct WeeklyOrderSummaryCard: View {
    let order: WeeklyOrder
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCurrent ? order.currentTitle : order.historyTitle)
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(order.summarySubtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(order.estimatedTotalMXN.currencyText)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
            }

            HStack(spacing: 10) {
                Label("\(order.storeCount) tiendas", systemImage: "storefront.fill")
                Label("\(order.totalPieces) pzas", systemImage: "shippingbox.fill")
            }
            .font(.caption)
            .foregroundColor(AppTheme.Colors.mutedGray)

            if let lastStoreName = order.entries.last?.store.name {
                Text("Última tienda: \(lastStoreName)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 2)
    }
}

private struct EmptyCurrentOrderCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cart")
                .foregroundColor(AppTheme.Colors.primaryBlue)

            Text("Aún no hay productos cargados desde la ruta.")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)

            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
    }
}

private struct WeeklyOrderDetailView: View {
    let order: WeeklyOrder

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundGray.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WeeklyOrderDetailHeader(order: order)

                    ForEach(order.entries) { entry in
                        WeeklyOrderStoreDetailCard(entry: entry)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Detalle del pedido")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WeeklyOrderDetailHeader: View {
    let order: WeeklyOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.currentTitle)
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(order.summarySubtitle)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }

                Spacer()

                Text(order.estimatedTotalMXN.currencyText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
            }

            HStack(spacing: 12) {
                OrderDetailMetric(title: "Tiendas", value: "\(order.storeCount)")
                OrderDetailMetric(title: "Piezas", value: "\(order.totalPieces)")
                OrderDetailMetric(title: "Merma", value: order.avoidedWasteMXN.currencyText)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
    }
}

private struct OrderDetailMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.mutedGray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WeeklyOrderStoreDetailCard: View {
    let entry: WeeklyOrderStoreEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.store.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(entry.store.address)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.totalPieces) pzas")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(entry.estimatedTotalMXN.currencyText)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.primaryBlue)
                }
            }

            if entry.recommendations.isEmpty {
                Text("Sin detalle de productos guardado para esta tienda.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            } else {
                VStack(spacing: 10) {
                    ForEach(entry.recommendations) { recommendation in
                        WeeklyOrderProductRow(
                            storeName: entry.store.name,
                            recommendation: recommendation
                        )
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 2)
    }
}

private struct WeeklyOrderProductRow: View {
    let storeName: String
    let recommendation: Recommendation

    private var quantity: Int {
        recommendation.editableQuantity
    }

    var body: some View {
        HStack(spacing: 12) {
            OrderProductThumbnail(product: recommendation.product)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.product.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("\(recommendation.product.brand) · \(recommendation.product.unitPriceMXN.currencyText) c/u")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)

                Text("Para \(storeName)")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(quantity)")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text((Double(quantity) * recommendation.product.unitPriceMXN).currencyText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
        .padding(10)
        .background(AppTheme.Colors.backgroundGray)
        .cornerRadius(AppTheme.Radii.small)
    }
}

private struct OrderProductThumbnail: View {
    let product: Product

    var body: some View {
        Group {
            if let imageName = product.imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppTheme.Colors.softBlue
                    VStack(spacing: 2) {
                        Image(systemName: "photo")
                            .font(.caption)
                        Text(product.name.prefix(1))
                            .font(.caption)
                            .fontWeight(.heavy)
                    }
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.small))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.small)
                .stroke(AppTheme.Colors.primaryBlue.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct OrdersSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
}

private extension WeeklyOrder {
    var currentTitle: String {
        status == .cart ? "Pedido en ruta" : "Pedido para siguiente martes"
    }

    var historyTitle: String {
        "Pedido \(formattedDate(finalizedAt ?? createdAt))"
    }

    var summarySubtitle: String {
        "\(routeName) · \(formattedTargetDate)"
    }

    var formattedTargetDate: String {
        "Entrega \(formattedDate(targetWeekStartDate))"
    }

    var estimatedTotalMXN: Double {
        entries.reduce(0) { $0 + $1.estimatedTotalMXN }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_MX")))
    }
}

private extension WeeklyOrderStoreEntry {
    var estimatedTotalMXN: Double {
        recommendations.reduce(0) { partialResult, recommendation in
            partialResult + (Double(recommendation.editableQuantity) * recommendation.product.unitPriceMXN)
        }
    }
}

private extension Double {
    var currencyText: String {
        formatted(.currency(code: "MXN").precision(.fractionLength(0)))
    }
}

#Preview {
    DailyOrdersView()
}

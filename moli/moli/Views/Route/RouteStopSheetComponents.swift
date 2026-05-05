import SwiftUI

// MARK: - Selected Stop Sheet

struct RouteSelectedStopSheet: View {
    let selectedStop: RouteStop?
    let isNavigationActive: Bool
    let routeErrorMessage: String?
    let startNavigationAction: () -> Void
    let openMapsAction: () -> Void
    let scanAction: () -> Void

    var body: some View {
        if let selectedStop {
            VStack(alignment: .leading, spacing: 16) {
                RouteStopHeader(stop: selectedStop, isNavigationActive: isNavigationActive)
                RouteStopStoreInfo(store: selectedStop.store)
                RouteStopMetrics(store: selectedStop.store)

                if let routeErrorMessage {
                    Text(routeErrorMessage)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.alertOrange)
                }

                RouteNavigationActions(
                    store: selectedStop.store,
                    startNavigationAction: startNavigationAction,
                    openMapsAction: openMapsAction,
                    scanAction: scanAction
                )
            }
            .padding(AppTheme.Radii.large)
        }
    }
}

// MARK: - Stop Header

private struct RouteStopHeader: View {
    let stop: RouteStop
    let isNavigationActive: Bool

    var body: some View {
        HStack {
            Text(isNavigationActive ? "NAVEGANDO · #\(stop.stopNumber)" : "TIENDA · #\(stop.stopNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.Colors.softBlue)
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .cornerRadius(AppTheme.Radii.small)

            Spacer()

            Text("Última visita hace \(stop.store.lastVisitDaysAgo) días")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
}

// MARK: - Store Info

private struct RouteStopStoreInfo: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(store.address)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
}

// MARK: - Metrics

private struct RouteStopMetrics: View {
    let store: Store

    var body: some View {
        HStack {
            RouteMetric(title: "DISTANCIA", value: "\(String(format: "%.1f", store.distanceKm)) km")

            Spacer()

            RouteMetric(title: "TIEMPO", value: "\(store.estimatedMinutes) min")

            Spacer()

            VStack(alignment: .trailing) {
                Text("ÚLTIMA")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(store.lastOrderPieces)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("pzas")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
            }
        }
    }
}

private struct RouteMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.mutedGray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Navigation Actions

private struct RouteNavigationActions: View {
    let store: Store
    let startNavigationAction: () -> Void
    let openMapsAction: () -> Void
    let scanAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: startNavigationAction) {
                HStack {
                    Image(systemName: "location.north.line.fill")
                    Text("INICIAR NAVEGACIÓN")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.Radii.medium)
            }

            HStack(spacing: 10) {
                Button(action: openMapsAction) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Abrir en Mapas")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.softBlue)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                    .cornerRadius(AppTheme.Radii.medium)
                }

                Button(action: scanAction) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Escanear")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.softBlue)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                    .cornerRadius(AppTheme.Radii.medium)
                }
            }
        }
    }
}

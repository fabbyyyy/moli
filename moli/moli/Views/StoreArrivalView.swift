import SwiftUI

struct StoreArrivalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: StoreArrivalViewModel

    init(store: Store) {
        _viewModel = State(initialValue: StoreArrivalViewModel(store: store))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundGray.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                StoreArrivalHeader(store: viewModel.store)
                LastOrderCard(store: viewModel.store)
                HandsFreeCard(isEnabled: $viewModel.isHandsFreeEnabled)

                Spacer()

                StoreArrivalBottomSection(store: viewModel.store)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Llegaste a la tienda")
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
    }

    private func dismissView() {
        dismiss()
    }
}

private struct StoreArrivalHeader: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PARADA #\(store.customerNumber.prefix(1)) · \(store.address)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.Colors.softBlue)
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .cornerRadius(AppTheme.Radii.small)

            Text(store.name)
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.top, 10)
    }
}

private struct LastOrderCard: View {
    let store: Store

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppTheme.Colors.softBlue)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.Colors.primaryBlue)
                        .font(.title3)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Última orden")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .fontWeight(.bold)
                Text("\(store.lastOrderPieces) piezas hace \(store.lastVisitDaysAgo) días")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
    }
}

private struct HandsFreeCard: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(AppTheme.Colors.primaryBlue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Manos libres")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Activa para guía por voz mientras trabajas")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            Spacer()
            Image(systemName: "mic.fill")
                .foregroundColor(isEnabled ? AppTheme.Colors.primaryBlue : AppTheme.Colors.mutedGray)
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
    }
}

private struct StoreArrivalBottomSection: View {
    let store: Store

    var body: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: ShelfScanCameraView(store: store)) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("ESCANEAR ANAQUEL")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.Radii.medium)
            }

            HStack {
                Text("Toma una foto del exhibidor")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.yellow)
                    Text("Ver pantalla bloqueada")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.primaryBlue)
                }
            }
        }
    }
}

#Preview {
    StoreArrivalView(store: MockStores.elPino)
}

import SwiftUI

struct ConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ConfirmationViewModel
    let nextStoreAction: () -> Void

    init(store: Store, pieces: Int, wasteAvoided: Double, nextStoreAction: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: ConfirmationViewModel(store: store, pieces: pieces, wasteAvoided: wasteAvoided))
        self.nextStoreAction = nextStoreAction
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundGray.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                ConfirmationCheckmark()
                ConfirmationTitle(storeName: viewModel.store.name)
                ConfirmationDetails(pieces: viewModel.pieces, wasteAvoided: viewModel.wasteAvoided)
                ConfirmationAlert()

                Spacer()

                Button(action: nextStoreAction) {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("SIGUIENTE TIENDA")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.Colors.primaryBlue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct ConfirmationCheckmark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.primaryBlue.opacity(0.1))
                .frame(width: 140, height: 140)

            Circle()
                .fill(AppTheme.Colors.primaryBlue)
                .frame(width: 100, height: 100)
                .shadow(color: AppTheme.Colors.primaryBlue.opacity(0.3), radius: 20, x: 0, y: 10)

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

private struct ConfirmationTitle: View {
    let storeName: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Agregado al carrito")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(storeName)
                .font(.headline)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
}

private struct ConfirmationDetails: View {
    let pieces: Int
    let wasteAvoided: Double

    var body: some View {
        HStack(spacing: 16) {
            ConfirmationDetailCard(
                title: "PEDIDO",
                value: "semana próxima",
                subtitle: "se cierra al terminar ruta",
                subtitleColor: AppTheme.Colors.mutedGray,
                isSubtitleBold: false
            )

            ConfirmationDetailCard(
                title: "PIEZAS",
                value: "\(pieces) pzas",
                subtitle: "Merma evitada $\(Int(wasteAvoided))",
                subtitleColor: AppTheme.Colors.primaryBlue,
                isSubtitleBold: true
            )
        }
        .padding(.horizontal)
    }
}

private struct ConfirmationDetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    let subtitleColor: Color
    let isSubtitleBold: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.mutedGray)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(subtitle)
                .font(.caption)
                .fontWeight(isSubtitleBold ? .bold : .regular)
                .foregroundColor(subtitleColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
    }
}

private struct ConfirmationAlert: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.Colors.alertOrange)
                .font(.title3)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Carrito semanal")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.warningText)

                Text("Esta sugerencia quedó guardada por tienda dentro del pedido general de la próxima semana.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.warningText)
            }
        }
        .padding()
        .background(AppTheme.Colors.alertYellow)
        .cornerRadius(AppTheme.Radii.medium)
        .padding(.horizontal)
    }
}

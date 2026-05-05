import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var isProfileEditorPresented = false
    @State private var profileNameDraft = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundGray.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HomeHeader(userName: viewModel.userName)
                        CurrentRouteCard(
                            routeName: viewModel.currentRouteName,
                            completedStores: viewModel.completedStores,
                            totalStores: viewModel.totalStores,
                            nextStoreName: viewModel.nextStoreName
                        )
                        ExpirationAlertsSection(alerts: viewModel.expiringProductAlerts)
                        HomeOrdersSection(orders: viewModel.readyOrderSummaries)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: presentProfileEditor) {
                        Image(systemName: "person.crop.circle")
                    }
                    .tint(AppTheme.Colors.primaryBlue)
                }
            }
            .sheet(isPresented: $isProfileEditorPresented) {
                ProfileEditorSheet(
                    name: $profileNameDraft,
                    saveAction: saveProfileName
                )
                .presentationDetents([.medium])
            }
            .task {
                loadDashboard()
            }
        }
    }

    private func loadDashboard() {
        viewModel.loadDashboard()
    }

    private func presentProfileEditor() {
        profileNameDraft = viewModel.userName
        isProfileEditorPresented = true
    }

    private func saveProfileName() {
        let trimmedName = profileNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        viewModel.userName = trimmedName
        isProfileEditorPresented = false
    }
}

private struct HomeHeader: View {
    let userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Buenos días, \(userName)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            HStack {
                Text("Moli")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.Colors.primaryBlue)

                Text("· Tu copiloto de ruta")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

private struct CurrentRouteCard: View {
    let routeName: String
    let completedStores: Int
    let totalStores: Int
    let nextStoreName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(routeName)
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.softBlue)
                    Text("\(completedStores) de \(totalStores) tiendas pendientes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "box.truck.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    )
            }

            Divider().background(Color.white.opacity(0.3))

            VStack(alignment: .leading) {
                Text("Siguiente parada:")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.softBlue)
                Text(nextStoreName)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            NavigationLink(destination: RouteMapView()) {
                HStack {
                    Text("CONTINUAR RUTA")
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .cornerRadius(AppTheme.Radii.medium)
            }
        }
        .padding(AppTheme.Radii.large)
        .background(AppTheme.Colors.primaryBlue)
        .cornerRadius(AppTheme.Radii.large)
        .shadow(color: AppTheme.Shadows.floating.color, radius: AppTheme.Shadows.floating.radius, x: AppTheme.Shadows.floating.x, y: AppTheme.Shadows.floating.y)
        .padding(.horizontal)
    }
}

private struct ExpirationAlertsSection: View {
    let alerts: [ProductExpirationAlert]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Alertas", subtitle: "Productos por caducar")

            ForEach(alerts) { alert in
                ExpirationAlertRow(alert: alert)
            }
        }
        .padding(.horizontal)
    }
}

private struct ExpirationAlertRow: View {
    let alert: ProductExpirationAlert

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title3)
                .foregroundColor(AppTheme.Colors.alertOrange)
                .frame(width: 42, height: 42)
                .background(AppTheme.Colors.alertYellow)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.productName)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("\(alert.quantity) piezas caducan en \(alert.daysUntilExpiration) días · \(alert.storeName)")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 2)
    }
}

private struct HomeOrdersSection: View {
    let orders: [ReadyOrderSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pedidos", subtitle: "Listos para revisar")

            if orders.isEmpty {
                EmptyOrdersRow()
            } else {
                ForEach(orders) { order in
                    ReadyOrderRow(order: order)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct ReadyOrderRow: View {
    let order: ReadyOrderSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.storeName)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("\(order.pieces) piezas sugeridas")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }

            Spacer()

            Text("$\(order.totalMXN)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.primaryBlue)
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 2)
    }
}

private struct EmptyOrdersRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .foregroundColor(AppTheme.Colors.primaryBlue)

            Text("Aún no hay pedidos listos.")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)

            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
    }
}

private struct SectionHeader: View {
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

private struct ProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    let saveAction: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Perfil") {
                    TextField("Nombre", text: $name)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: dismissSheet)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: saveAction)
                }
            }
        }
    }

    private func dismissSheet() {
        dismiss()
    }
}

#Preview {
    HomeView()
}

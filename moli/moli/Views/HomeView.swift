import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var isProfileEditorPresented = false
    @State private var profileNameDraft = ""
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundGray.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HomeHeader(userName: viewModel.userName)
                        
                        if viewModel.userName.lowercased() == "antonio" {
                            AntonioNoticeCard()
                        }
                        
                        CurrentRouteCard(
                            routeName: viewModel.currentRouteName,
                            completedStores: viewModel.completedStores,
                            totalStores: viewModel.totalStores,
                            nextStoreName: viewModel.nextStoreName,
                            onStartRoute: { selectedTab = 1 }
                        )
                        
                        CoursesSection()

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
    let onStartRoute: () -> Void

    var body: some View {
        Button(action: onStartRoute) {
            ZStack(alignment: .topTrailing) {
                AppTheme.Colors.primaryBlue

                Image("bimbo_truck")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140)
                    .padding(.top, 4)
                    .padding(.trailing, 4)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("¡Comencemos con tu ruta del día hoy!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            Text(routeName)
                                .font(.headline)
                                .foregroundColor(AppTheme.Colors.softBlue)
                                
                            Text("Tienes \(totalStores - completedStores) tiendas pendientes.")
                                .font(.footnote)
                                .foregroundColor(.white)
                                
                            HStack(spacing: 4) {
                                Text("Continuar ruta")
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.bold))
                            }
                            .font(.footnote)
                            .foregroundColor(AppTheme.Colors.softBlue)
                            .padding(.top, 8)
                        }
                        Spacer(minLength: 120)
                    }
                }
                .padding(AppTheme.Radii.large)
            }
            .cornerRadius(AppTheme.Radii.large)
            .shadow(color: AppTheme.Shadows.floating.color, radius: AppTheme.Shadows.floating.radius, x: AppTheme.Shadows.floating.x, y: AppTheme.Shadows.floating.y)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

private struct CoursesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cursos para ti", subtitle: "Desarrollo personal y profesional")
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    CourseCard(
                        title: "Finanzas Personales",
                        subtitle: "Aprende a administrar tu dinero",
                        url: "https://www.grupobimbo.com"
                    )
                    CourseCard(
                        title: "Excel Básico",
                        subtitle: "Domina las hojas de cálculo",
                        url: "https://www.grupobimbo.com"
                    )
                    CourseCard(
                        title: "Mejorando la Familia",
                        subtitle: "Tips para la vida diaria",
                        url: "https://www.grupobimbo.com"
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct CourseCard: View {
    let title: String
    let subtitle: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(width: 240, alignment: .topLeading)
            .background(AppTheme.Colors.cardWhite)
            .cornerRadius(AppTheme.Radii.medium)
            .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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

private struct AntonioNoticeCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Cambio temporal de ruta")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Debido a la ausencia de Luis esta semana, se ha reasignado su ruta a tu perfil. Por favor atiende los pendientes indicados.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(AppTheme.Colors.softBlue.opacity(0.3))
        .cornerRadius(AppTheme.Radii.medium)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
}

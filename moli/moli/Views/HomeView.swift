import SwiftUI
import AVFoundation

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

                        RouteCoachWidget(storeName: viewModel.nextStoreName)

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
                        subtitle: "Tips prácticos para rendir tu quincena y ahorrar sin complicaciones.",
                        imageName: "finanzas_personales",
                        url: "https://www.grupobimbo.com"
                    )
                    CourseCard(
                        title: "Excel Básico",
                        subtitle: "Agiliza tus reportes y ahorra tiempo con trucos súper fáciles de usar.",
                        imageName: "excel",
                        url: "https://www.grupobimbo.com"
                    )
                    CourseCard(
                        title: "Mejorando la Familia",
                        subtitle: "Ideas útiles para convivir mejor en casa y apoyar a los tuyos.",
                        imageName: "mejor_papa",
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
    let imageName: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: 12) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 240, height: 120)
                    .clipped()
                
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

// MARK: - Route Coach Widget
private struct RouteCoachWidget: View {
    let storeName: String
    @State private var currentStep = 0
    @State private var synth = AVSpeechSynthesizer()

    private var steps: [CoachStep] {
        CoachStep.generate(for: storeName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.Colors.primaryBlue)
                            .frame(width: 32, height: 32)
                        Image(systemName: "sparkles")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                    }
                    Text("Recomendaciones")
                        .font(.subheadline).bold()
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                Text(storeName)
                    .font(.caption).bold()
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 14)

            // Step label
            if currentStep < steps.count {
                let step = steps[currentStep]

                Text("INSTRUCCIÓN \(step.number) DE \(steps.count) · \(step.category)")
                    .font(.caption).bold()
                    .foregroundColor(AppTheme.Colors.alertOrange)
                    .padding(.bottom, 6)

                Text(step.instruction)
                    .font(.body).bold()
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                // Waveform decorativa
                HStack(spacing: 3) {
                    ForEach(0..<9, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppTheme.Colors.primaryBlue)
                            .frame(width: 3, height: CGFloat([8,14,10,18,12,16,9,13,7][i]))
                    }
                    Text("Leyendo en voz alta")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 6)
                }
                .padding(.bottom, 14)

                // Botones
                HStack(spacing: 10) {
                    Button {
                        if currentStep < steps.count - 1 { currentStep += 1; speak(steps[currentStep].instruction) }
                    } label: {
                        Text("Saltar")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Button {
                        if currentStep < steps.count - 1 {
                            currentStep += 1
                            speak(steps[currentStep].instruction)
                        } else {
                            currentStep = 0
                            speak(steps[0].instruction)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentStep < steps.count - 1 ? "Hecho" : "Reiniciar")
                            Image(systemName: currentStep < steps.count - 1 ? "checkmark" : "arrow.counterclockwise")
                        }
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(AppTheme.Colors.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.bottom, 12)

                // Impacto
                Text(step.impact)
                    .font(.caption2).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(hex: "0C1A30"))
        .cornerRadius(AppTheme.Radii.large)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .onAppear { speak(steps[currentStep].instruction) }
    }

    private func speak(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utt.rate = 0.48
        synth.speak(utt)
    }
}

private struct CoachStep {
    let number: Int
    let category: String
    let instruction: String
    let impact: String

    static func generate(for storeName: String) -> [CoachStep] {
        let orders = LocalPersistenceService.shared.weeklyOrders
        let storeOrder = orders.first?.entries.first { $0.store.name == storeName }
        let pieces = storeOrder?.totalPieces ?? 14
        let mainProduct = storeOrder?.recommendations.first?.product.name ?? "Takis Morados"


        return [
            CoachStep(number: 1, category: "BAJAR PRODUCTO",
                      instruction: "Baja \(pieces) piezas de \(mainProduct) del camión para \(storeName).",
                      impact: "Merma evitada visita +$\(pieces * 19)"),
            CoachStep(number: 2, category: "RETIRAR MERMA",
                      instruction: "Antes de surtir, revisa el anaquel y retira los productos con sticker rojo vencidos.",
                      impact: "Evita devoluciones"),
            CoachStep(number: 3, category: "REPONER",
                      instruction: "Coloca \(mainProduct) en los huecos vacíos. Pon el lote nuevo detrás del existente.",
                      impact: "Asegura venta del día"),
            CoachStep(number: 4, category: "CONFIRMAR",
                      instruction: "Toma foto del anaquel surtido y confirma el pedido en la app.",
                      impact: "Visita completada ✓")
        ]
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

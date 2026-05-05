import SwiftUI

struct CoachLockScreenPreviewView: View {
    var body: some View {
        ZStack {
            Color(hex: "0C1A30").ignoresSafeArea()

            VStack(spacing: 20) {
                LockScreenHeader()
                Spacer()
                MoliNotificationCard()
                Spacer()
                LockScreenQuickActions()
            }
        }
    }
}

private struct LockScreenHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundColor(.white)

            Text("9:41")
                .font(.system(size: 80, weight: .thin))
                .foregroundColor(.white)

            Text("martes, 11 de mayo")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 40)
    }
}

private struct MoliNotificationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.white)
                Text("Route Coach · En visita")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("Ahora")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Text("INSTRUCCIÓN 2 DE 4 · REPONER")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.alertOrange)

            Text("Llena los 3 huecos del nivel 1 con Pan Blanco y Gansito. Coloca el lote nuevo detrás del existente.")
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("Merma evitada visita +$480")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.white)

                Spacer()
            }

            MoliNotificationActions()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .background(BlurView(style: .systemThinMaterialDark))
        .cornerRadius(24)
        .padding(.horizontal)
    }
}

private struct MoliNotificationActions: View {
    var body: some View {
        HStack(spacing: 12) {
            Button(action: skipInstruction) {
                Text("Saltar")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: completeInstruction) {
                HStack {
                    Text("Hecho")
                    Image(systemName: "checkmark")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }

    private func skipInstruction() {}

    private func completeInstruction() {}
}

private struct LockScreenQuickActions: View {
    var body: some View {
        HStack {
            LockScreenIcon(systemName: "flashlight.off.fill")

            Spacer()

            LockScreenIcon(systemName: "camera.fill")
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 30)
    }
}

private struct LockScreenIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.title2)
            .foregroundColor(.white)
            .padding(16)
            .background(Color.white.opacity(0.2))
            .clipShape(Circle())
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    CoachLockScreenPreviewView()
}

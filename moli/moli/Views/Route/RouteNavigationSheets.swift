import MapKit
import SwiftUI

// MARK: - Navigation End Sheet

struct RouteNavigationEndSheet: View {
    let stop: RouteStop?
    let arrivalTimeText: String
    let travelTimeText: String
    let distanceText: String
    let distanceUnitText: String
    let isExpanded: Bool
    let callStoreAction: () -> Void
    let scanStoreAction: () -> Void
    let stopNavigationAction: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .glassEffect(.regular, in: .rect(cornerRadius: 34))
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34))
        }
    }

    private var content: some View {
        VStack(spacing: 18) {
            NavigationSummaryMetrics(
                arrivalTimeText: arrivalTimeText,
                travelTimeText: travelTimeText,
                distanceText: distanceText,
                distanceUnitText: distanceUnitText
            )

            if isExpanded {
                VStack(spacing: 16) {
                    if let stop {
                        DestinationCallRow(store: stop.store, callStoreAction: callStoreAction)
                    }

                    Button(action: scanStoreAction) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                            Text("Escanear anaquel")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(AppTheme.Colors.softBlue)
                        .foregroundColor(AppTheme.Colors.primaryBlue)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: stopNavigationAction) {
                        Text("Terminar ruta")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(AppTheme.Colors.bimboRed)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, isExpanded ? 18 : 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }
}

// MARK: - Summary Metrics

private struct NavigationSummaryMetrics: View {
    let arrivalTimeText: String
    let travelTimeText: String
    let distanceText: String
    let distanceUnitText: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            NavigationSummaryMetric(value: arrivalTimeText, label: "arrival")
            NavigationSummaryMetric(value: travelTimeText.replacingOccurrences(of: " min", with: ""), label: "min")
            NavigationSummaryMetric(value: distanceText, label: distanceUnitText)
        }
    }
}

private struct NavigationSummaryMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DestinationCallRow: View {
    let store: Store
    let callStoreAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "building.2.fill")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.brown.opacity(0.82))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text(store.address)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button(action: callStoreAction) {
                Image(systemName: "phone.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 52, height: 52)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.Colors.cardWhite.opacity(0.62), in: Capsule())
    }
}

// MARK: - Voice Controls Sheet

struct RouteVoiceControlsSheet: View {
    @Binding var isVoiceGuidanceEnabled: Bool
    @Binding var selectedVolume: RouteVoiceVolume
    let closeAction: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .glassEffect(.regular, in: .rect(cornerRadius: 34))
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34))
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Voice Controls")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Button(action: closeAction) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.Colors.cardWhite.opacity(0.55), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VoiceMutePicker(isVoiceGuidanceEnabled: $isVoiceGuidanceEnabled)

            VStack(alignment: .leading, spacing: 10) {
                Text("Volume")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                VStack(spacing: 0) {
                    ForEach(RouteVoiceVolume.allCases) { volume in
                        Button {
                            selectedVolume = volume
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: volume == selectedVolume ? "waveform.circle.fill" : "waveform.circle")
                                    .font(.title2)
                                    .foregroundColor(volume == selectedVolume ? .blue : AppTheme.Colors.mutedGray)

                                Text(volume.title)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.textPrimary)

                                Spacer()

                                if volume == selectedVolume {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 18)
                            .frame(height: 58)
                        }
                        .buttonStyle(.plain)

                        if volume != RouteVoiceVolume.allCases.last {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .background(AppTheme.Colors.cardWhite.opacity(0.52), in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 26)
    }
}

// MARK: - Voice Mute Picker

private struct VoiceMutePicker: View {
    @Binding var isVoiceGuidanceEnabled: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button {
                isVoiceGuidanceEnabled = false
            } label: {
                VoiceMuteOption(
                    systemImage: "speaker.slash.fill",
                    title: "Muted",
                    isSelected: !isVoiceGuidanceEnabled
                )
            }
            .buttonStyle(.plain)

            Button {
                isVoiceGuidanceEnabled = true
            } label: {
                VoiceMuteOption(
                    systemImage: "speaker.wave.3.fill",
                    title: "Unmuted",
                    isSelected: isVoiceGuidanceEnabled
                )
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(AppTheme.Colors.cardWhite.opacity(0.45), in: Capsule())
    }
}

private struct VoiceMuteOption: View {
    let systemImage: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.mutedGray)
                .frame(height: 52)

            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                Capsule()
                    .fill(AppTheme.Colors.cardWhite.opacity(0.82))
            }
        }
    }
}

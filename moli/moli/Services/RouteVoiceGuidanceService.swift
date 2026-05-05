import AVFoundation
import CoreLocation
import MapKit

@MainActor
final class RouteVoiceGuidanceService {
    private let synthesizer = AVSpeechSynthesizer()
    private var spokenStepIndexes: Set<Int> = []
    private var didAnnounceStart = false

    func start(route: MKRoute?, destinationName: String) {
        spokenStepIndexes = []
        didAnnounceStart = true
        speak("Iniciando navegacion hacia \(destinationName).")

        if let firstInstruction = route?.voiceInstructions.first {
            speak("Sigue la ruta. \(firstInstruction)")
        }
    }

    func update(currentLocation: CLLocationCoordinate2D?, route: MKRoute?) {
        guard let currentLocation, let route else {
            return
        }

        if !didAnnounceStart {
            speak("Sigue la ruta marcada.")
            didAnnounceStart = true
        }

        let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        for (index, step) in route.steps.enumerated() {
            guard !spokenStepIndexes.contains(index),
                  let instruction = step.voiceInstruction,
                  let coordinate = step.polyline.firstCoordinate else {
                continue
            }

            let stepLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = userLocation.distance(from: stepLocation)
            guard distance <= 180 else {
                continue
            }

            spokenStepIndexes.insert(index)
            speak("En \(Int(distance.rounded())) metros, \(instruction).")
            break
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        spokenStepIndexes = []
        didAnnounceStart = false
    }

    private func speak(_ text: String) {
        guard !synthesizer.isSpeaking else {
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synthesizer.speak(utterance)
    }
}

private extension MKRoute {
    var voiceInstructions: [String] {
        steps.compactMap(\.voiceInstruction)
    }
}

private extension MKRoute.Step {
    var voiceInstruction: String? {
        let cleanedInstruction = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedInstruction.isEmpty ? nil : cleanedInstruction
    }
}

private extension MKPolyline {
    var firstCoordinate: CLLocationCoordinate2D? {
        guard pointCount > 0 else {
            return nil
        }

        return points()[0].coordinate
    }
}

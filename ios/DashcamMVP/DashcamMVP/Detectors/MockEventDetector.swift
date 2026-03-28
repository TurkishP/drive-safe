import AVFoundation
import Foundation

final class MockEventDetector: EventDetector {
    private var frameCounter = 0
    private var lastEmissionDate = Date.distantPast

    func process(sampleBuffer: CMSampleBuffer, timestamp: Date, sensitivity: Double) -> SuspectedEvent? {
        frameCounter += 1

        // TODO: Replace this mock sampler with real lane/vehicle perception output.
        guard frameCounter.isMultiple(of: 45) else { return nil }

        let minimumSpacing = max(8.0, 20.0 - (sensitivity * 8.0))
        guard timestamp.timeIntervalSince(lastEmissionDate) > minimumSpacing else { return nil }

        let threshold = max(0.94, 0.985 - (sensitivity * 0.03))
        guard Double.random(in: 0...1) > threshold else { return nil }

        let event = SuspectedEvent(
            type: Bool.random() ? .centerLineCrossing : .solidLineLaneChange,
            timestamp: timestamp,
            confidence: Double.random(in: 0.58...0.86),
            summary: "Mock detector emitted a candidate for UI and storage pipeline testing."
        )

        lastEmissionDate = timestamp
        return event
    }

    func makeManualEvent(timestamp: Date) -> SuspectedEvent {
        SuspectedEvent(
            type: Bool.random() ? .centerLineCrossing : .solidLineLaneChange,
            timestamp: timestamp,
            confidence: 0.82,
            summary: "Manual test event generated from dashcam mode."
        )
    }

    func reset() {
        frameCounter = 0
        lastEmissionDate = .distantPast
    }
}

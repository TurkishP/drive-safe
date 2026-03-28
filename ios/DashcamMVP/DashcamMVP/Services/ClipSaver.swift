import Foundation

final class ClipSaver {
    private let rollingBufferManager: RollingBufferManager
    private let eventStore: EventStore

    init(rollingBufferManager: RollingBufferManager, eventStore: EventStore) {
        self.rollingBufferManager = rollingBufferManager
        self.eventStore = eventStore
    }

    func saveClip(for suspectedEvent: SuspectedEvent, settings: AppSettings) async throws -> DetectedEvent {
        let clipURL = try await rollingBufferManager.buildClip(
            around: suspectedEvent.timestamp,
            preEvent: settings.preEventSeconds,
            postEvent: settings.postEventSeconds,
            destinationDirectory: eventStore.clipsDirectoryURL
        )

        let detectedEvent = DetectedEvent(
            id: UUID(),
            eventType: suspectedEvent.type,
            timestamp: suspectedEvent.timestamp,
            confidence: suspectedEvent.confidence,
            clipRelativePath: clipURL.lastPathComponent,
            reviewState: .pending,
            notes: nil,
            duration: settings.preEventSeconds + settings.postEventSeconds,
            detectorSummary: suspectedEvent.summary
        )

        await MainActor.run {
            eventStore.add(detectedEvent)
        }

        return detectedEvent
    }
}

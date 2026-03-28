import Foundation

final class AppEnvironment: ObservableObject {
    let settingsStore: AppSettingsStore
    let eventStore: EventStore
    let coordinator: DashcamCoordinator

    init() {
        let settingsStore = AppSettingsStore()
        let eventStore = EventStore()
        let rollingBufferManager = RollingBufferManager()
        let cameraManager = CameraManager()
        let detector = BasicPerceptionDetector()
        let clipSaver = ClipSaver(rollingBufferManager: rollingBufferManager, eventStore: eventStore)

        self.settingsStore = settingsStore
        self.eventStore = eventStore
        self.coordinator = DashcamCoordinator(
            cameraManager: cameraManager,
            settingsStore: settingsStore,
            eventStore: eventStore,
            rollingBufferManager: rollingBufferManager,
            detector: detector,
            clipSaver: clipSaver
        )
    }
}

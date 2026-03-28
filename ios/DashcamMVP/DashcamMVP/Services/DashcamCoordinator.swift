import SwiftUI
import UIKit

final class DashcamCoordinator: ObservableObject {
    @Published private(set) var isDashcamActive = false
    @Published private(set) var lastStatusMessage = "Ready"
    @Published private(set) var totalStorageBytes: Int64 = 0
    @Published private(set) var pendingExports = 0
    @Published private(set) var latestPerceptionSnapshot: PerceptionSnapshot?

    let cameraManager: CameraManager
    let settingsStore: AppSettingsStore
    let eventStore: EventStore

    private let rollingBufferManager: RollingBufferManager
    private let detector: EventDetector
    private let clipSaver: ClipSaver
    private let processingQueue = DispatchQueue(label: "dashcam.coordinator.processing")
    private var lastTriggeredAt = Date.distantPast

    init(
        cameraManager: CameraManager,
        settingsStore: AppSettingsStore,
        eventStore: EventStore,
        rollingBufferManager: RollingBufferManager,
        detector: EventDetector,
        clipSaver: ClipSaver
    ) {
        self.cameraManager = cameraManager
        self.settingsStore = settingsStore
        self.eventStore = eventStore
        self.rollingBufferManager = rollingBufferManager
        self.detector = detector
        self.clipSaver = clipSaver

        detector.onPerceptionUpdate = { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.latestPerceptionSnapshot = snapshot
            }
        }

        wireCameraCallbacks()
        refreshStorageUsage()
    }

    func startDashcamMode() {
        let settings = settingsStore.settings
        rollingBufferManager.configure(bufferLength: settings.rollingBufferLength)
        cameraManager.segmentDuration = settings.segmentDuration
        detector.reset()
        lastTriggeredAt = .distantPast

        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
            self.lastStatusMessage = "Starting foreground dashcam mode"
            self.isDashcamActive = true
        }

        cameraManager.startSession()
    }

    func stopDashcamMode() {
        cameraManager.stopSession()
        detector.reset()

        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            self.isDashcamActive = false
            self.lastStatusMessage = "Dashcam mode stopped"
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard isDashcamActive else { return }

        if phase != .active {
            stopDashcamMode()
        }
    }

    func simulateDetection() {
        scheduleCapture(for: detector.makeManualEvent(timestamp: Date()))
    }

    func refreshStorageUsage() {
        let clipBytes = eventStore.totalClipBytes()
        let bufferBytes = rollingBufferManager.tempStorageBytes()
        DispatchQueue.main.async {
            self.totalStorageBytes = clipBytes + bufferBytes
        }
    }

    private func wireCameraCallbacks() {
        cameraManager.onSegmentFinished = { [weak self] url, startDate, endDate in
            guard let self else { return }

            let destinationURL = self.rollingBufferManager.nextSegmentURL()
            try? FileManager.default.moveItem(at: url, to: destinationURL)
            self.rollingBufferManager.registerFinishedSegment(url: destinationURL, startDate: startDate, endDate: endDate)
            self.refreshStorageUsage()
        }

        cameraManager.onSampleBuffer = { [weak self] sampleBuffer, timestamp in
            self?.processingQueue.async {
                guard let self else { return }
                let sensitivity = self.settingsStore.settings.sensitivity

                guard let suspectedEvent = self.detector.process(sampleBuffer: sampleBuffer, timestamp: timestamp, sensitivity: sensitivity) else {
                    return
                }

                self.scheduleCapture(for: suspectedEvent)
            }
        }
    }

    private func scheduleCapture(for suspectedEvent: SuspectedEvent) {
        let settings = settingsStore.settings
        let cooldown = max(4.0, min(settings.preEventSeconds, settings.postEventSeconds) / 2.0)
        guard suspectedEvent.timestamp.timeIntervalSince(lastTriggeredAt) > cooldown else { return }
        lastTriggeredAt = suspectedEvent.timestamp

        DispatchQueue.main.async {
            self.pendingExports += 1
            self.lastStatusMessage = "Suspected \(suspectedEvent.type.title) detected"
        }

        Task {
            do {
                let delay = UInt64(max(settings.postEventSeconds, self.cameraManager.segmentDuration) * 1_000_000_000)
                try await Task.sleep(nanoseconds: delay)
                _ = try await self.clipSaver.saveClip(for: suspectedEvent, settings: settings)

                DispatchQueue.main.async {
                    self.lastStatusMessage = "Saved clip for \(suspectedEvent.type.title)"
                    self.pendingExports = max(0, self.pendingExports - 1)
                    self.refreshStorageUsage()
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastStatusMessage = "Clip save failed: \(error.localizedDescription)"
                    self.pendingExports = max(0, self.pendingExports - 1)
                }
            }
        }
    }
}

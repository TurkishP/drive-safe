import AVFoundation
import Foundation

final class CameraManager: NSObject, ObservableObject {
    enum SessionState: String {
        case idle
        case starting
        case running
        case stopping
        case failed
    }

    @Published private(set) var sessionState: SessionState = .idle
    @Published private(set) var authorizationDenied = false
    @Published private(set) var lastErrorMessage: String?

    let session = AVCaptureSession()

    var segmentDuration: TimeInterval = 2
    var onSampleBuffer: ((CMSampleBuffer, Date) -> Void)?
    var onSegmentFinished: ((URL, Date, Date) -> Void)?

    private let movieOutput = AVCaptureMovieFileOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "dashcam.camera.session")
    private let sampleBufferQueue = DispatchQueue(label: "dashcam.camera.frames")
    private var isConfigured = false
    private var shouldContinueRecording = false
    private var rotationWorkItem: DispatchWorkItem?
    private var segmentStartDates: [URL: Date] = [:]

    func startSession() {
        updateSessionState(.starting)

        requestVideoAccessIfNeeded { [weak self] granted in
            guard let self else { return }

            guard granted else {
                DispatchQueue.main.async {
                    self.authorizationDenied = true
                    self.lastErrorMessage = "Camera access is required for dashcam mode."
                }
                self.updateSessionState(.failed)
                return
            }

            self.sessionQueue.async {
                do {
                    if self.isConfigured == false {
                        try self.configureSession()
                    }

                    self.shouldContinueRecording = true
                    if self.session.isRunning == false {
                        self.session.startRunning()
                    }
                    self.startNewSegment()
                    self.updateSessionState(.running)
                } catch {
                    self.updateSessionState(.failed)
                    DispatchQueue.main.async {
                        self.lastErrorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    func stopSession() {
        updateSessionState(.stopping)

        sessionQueue.async {
            self.shouldContinueRecording = false
            self.rotationWorkItem?.cancel()
            self.rotationWorkItem = nil

            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }

            if self.session.isRunning {
                self.session.stopRunning()
            }

            self.segmentStartDates.removeAll()
            self.updateSessionState(.idle)
        }
    }

    private func requestVideoAccessIfNeeded(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        default:
            completion(false)
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .high
        defer {
            session.commitConfiguration()
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.cameraUnavailable
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        guard session.canAddOutput(movieOutput) else {
            throw CameraError.cannotAddMovieOutput
        }
        session.addOutput(movieOutput)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        guard session.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddVideoDataOutput
        }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        if let movieConnection = movieOutput.connection(with: .video), movieConnection.isVideoOrientationSupported {
            movieConnection.videoOrientation = .portrait
        }

        isConfigured = true
    }

    private func startNewSegment() {
        guard shouldContinueRecording else { return }
        guard movieOutput.isRecording == false else { return }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        try? FileManager.default.removeItem(at: fileURL)
        segmentStartDates[fileURL] = Date()
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
        }

        rotationWorkItem?.cancel()
        rotationWorkItem = workItem
        sessionQueue.asyncAfter(deadline: .now() + segmentDuration, execute: workItem)
    }

    private func updateSessionState(_ newValue: SessionState) {
        DispatchQueue.main.async {
            self.sessionState = newValue
        }
    }
}

extension CameraManager: AVCaptureMovieFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        segmentStartDates[fileURL] = segmentStartDates[fileURL] ?? Date()
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let startDate = segmentStartDates.removeValue(forKey: outputFileURL) ?? Date()
        let endDate = Date()

        if let error {
            DispatchQueue.main.async {
                self.lastErrorMessage = error.localizedDescription
            }
        } else {
            onSegmentFinished?(outputFileURL, startDate, endDate)
        }

        if shouldContinueRecording {
            startNewSegment()
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onSampleBuffer?(sampleBuffer, Date())
    }
}

enum CameraError: LocalizedError {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddMovieOutput
    case cannotAddVideoDataOutput

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "The rear camera is not available on this device."
        case .cannotAddInput:
            return "The app could not create the camera input."
        case .cannotAddMovieOutput:
            return "The app could not start segmented video recording."
        case .cannotAddVideoDataOutput:
            return "The app could not start frame delivery for event detection."
        }
    }
}

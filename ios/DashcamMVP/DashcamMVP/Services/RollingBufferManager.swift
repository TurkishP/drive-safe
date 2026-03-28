import AVFoundation
import Foundation

final class RollingBufferManager {
    struct SegmentRecord: Identifiable {
        let id = UUID()
        let url: URL
        let startDate: Date
        let endDate: Date
    }

    private var segments: [SegmentRecord] = []
    private var bufferLength: TimeInterval = 30
    private let queue = DispatchQueue(label: "dashcam.buffer.queue")
    private let fileManager: FileManager
    private let segmentsDirectoryURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.segmentsDirectoryURL = baseURL
            .appendingPathComponent("DashcamMVP", isDirectory: true)
            .appendingPathComponent("RollingSegments", isDirectory: true)

        try? fileManager.createDirectory(at: segmentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    func configure(bufferLength: TimeInterval) {
        queue.sync {
            self.bufferLength = bufferLength
            self.cleanupExpiredSegments(referenceDate: Date())
        }
    }

    func nextSegmentURL() -> URL {
        segmentsDirectoryURL.appendingPathComponent("\(UUID().uuidString).mov")
    }

    func registerFinishedSegment(url: URL, startDate: Date, endDate: Date) {
        queue.sync {
            let record = SegmentRecord(url: url, startDate: startDate, endDate: endDate)
            segments.append(record)
            segments.sort(by: { $0.startDate < $1.startDate })
            cleanupExpiredSegments(referenceDate: endDate)
        }
    }

    func buildClip(
        around eventDate: Date,
        preEvent: TimeInterval,
        postEvent: TimeInterval,
        destinationDirectory: URL
    ) async throws -> URL {
        let windowStart = eventDate.addingTimeInterval(-preEvent)
        let windowEnd = eventDate.addingTimeInterval(postEvent)

        let relevantSegments = queue.sync {
            segments.filter { segment in
                segment.endDate > windowStart && segment.startDate < windowEnd
            }
        }

        guard relevantSegments.isEmpty == false else {
            throw RollingBufferError.noSegmentsAvailable
        }

        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw RollingBufferError.cannotCreateComposition
        }
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        for segment in relevantSegments {
            let asset = AVURLAsset(url: segment.url)
            let clipStartDate = max(segment.startDate, windowStart)
            let clipEndDate = min(segment.endDate, windowEnd)
            let sourceStartSeconds = clipStartDate.timeIntervalSince(segment.startDate)
            let durationSeconds = clipEndDate.timeIntervalSince(clipStartDate)
            let destinationStartSeconds = clipStartDate.timeIntervalSince(windowStart)

            guard durationSeconds > 0 else { continue }

            let sourceTimeRange = CMTimeRange(
                start: CMTime(seconds: sourceStartSeconds, preferredTimescale: 600),
                duration: CMTime(seconds: durationSeconds, preferredTimescale: 600)
            )
            let destinationTime = CMTime(seconds: destinationStartSeconds, preferredTimescale: 600)

            if let sourceVideoTrack = try await asset.loadTracks(withMediaType: .video).first {
                try videoTrack.insertTimeRange(sourceTimeRange, of: sourceVideoTrack, at: destinationTime)
                videoTrack.preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
            }

            if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                try audioTrack?.insertTimeRange(sourceTimeRange, of: sourceAudioTrack, at: destinationTime)
            }
        }

        let outputURL = destinationDirectory.appendingPathComponent("event-\(UUID().uuidString).mov")
        try? fileManager.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw RollingBufferError.cannotCreateExportSession
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = false

        try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                if let error = exportSession.error {
                    continuation.resume(throwing: error)
                } else if exportSession.status == .completed {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: RollingBufferError.exportFailed)
                }
            }
        }

        return outputURL
    }

    func tempStorageBytes() -> Int64 {
        queue.sync {
            segments.reduce(into: Int64(0)) { partialResult, segment in
                let values = try? segment.url.resourceValues(forKeys: [.fileSizeKey])
                partialResult += Int64(values?.fileSize ?? 0)
            }
        }
    }

    func clear() {
        queue.sync {
            for segment in segments {
                try? fileManager.removeItem(at: segment.url)
            }
            segments.removeAll()
        }
    }

    private func cleanupExpiredSegments(referenceDate: Date) {
        let expirationDate = referenceDate.addingTimeInterval(-bufferLength)
        let expired = segments.filter { $0.endDate < expirationDate }
        segments.removeAll { $0.endDate < expirationDate }

        for segment in expired {
            try? fileManager.removeItem(at: segment.url)
        }
    }
}

enum RollingBufferError: LocalizedError {
    case noSegmentsAvailable
    case cannotCreateComposition
    case cannotCreateExportSession
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .noSegmentsAvailable:
            return "No rolling-buffer segments are available for this event window."
        case .cannotCreateComposition:
            return "The app could not create a video composition for the saved clip."
        case .cannotCreateExportSession:
            return "The app could not start exporting the event clip."
        case .exportFailed:
            return "The event clip export failed."
        }
    }
}

import AVFoundation
import CoreGraphics
import Foundation

final class BasicPerceptionDetector: EventDetector {
    var onPerceptionUpdate: ((PerceptionSnapshot) -> Void)?

    private var frameCounter = 0
    private var previousFrame: DownsampledFrame?
    private var tracker = VehicleTracker()
    private var previousVehicleSides: [Int: CGFloat] = [:]
    private let workingWidth = 96
    private let workingHeight = 54

    func process(sampleBuffer: CMSampleBuffer, timestamp: Date, sensitivity: Double) -> SuspectedEvent? {
        frameCounter += 1
        guard frameCounter.isMultiple(of: 6) else { return nil }

        guard let frame = DownsampledFrame.make(from: sampleBuffer, width: workingWidth, height: workingHeight) else {
            return nil
        }

        let lanes = detectLanes(in: frame)
        let vehicleBoxes = detectVehicleCandidates(in: frame)
        let trackedVehicles = tracker.update(candidates: vehicleBoxes, timestamp: timestamp)

        let snapshot = PerceptionSnapshot(
            timestamp: timestamp,
            frameSize: CGSize(width: frame.width, height: frame.height),
            lanes: lanes,
            trackedVehicles: trackedVehicles,
            debugSummary: "Detected \(trackedVehicles.count) vehicle candidates and \(lanes.count) lane boundaries."
        )
        onPerceptionUpdate?(snapshot)

        previousFrame = frame

        return inferEvent(from: trackedVehicles, lanes: lanes, timestamp: timestamp, sensitivity: sensitivity)
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
        previousFrame = nil
        tracker = VehicleTracker()
        previousVehicleSides.removeAll()
    }

    private func detectLanes(in frame: DownsampledFrame) -> [LaneLine] {
        let startRow = Int(Double(frame.height) * 0.55)
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []

        for y in stride(from: startRow, to: frame.height - 2, by: 3) {
            if let leftX = strongestEdgeX(in: frame, row: y, xRange: 8..<(frame.width / 2), targetX: frame.width / 3) {
                leftPoints.append(CGPoint(x: CGFloat(leftX) / CGFloat(frame.width), y: CGFloat(y) / CGFloat(frame.height)))
            }

            if let rightX = strongestEdgeX(in: frame, row: y, xRange: (frame.width / 2)..<(frame.width - 8), targetX: (frame.width * 2) / 3) {
                rightPoints.append(CGPoint(x: CGFloat(rightX) / CGFloat(frame.width), y: CGFloat(y) / CGFloat(frame.height)))
            }
        }

        var lanes: [LaneLine] = []
        if let lane = fitLaneLine(points: leftPoints, isLeft: true) {
            lanes.append(lane)
        }
        if let lane = fitLaneLine(points: rightPoints, isLeft: false) {
            lanes.append(lane)
        }
        return lanes
    }

    private func strongestEdgeX(in frame: DownsampledFrame, row: Int, xRange: Range<Int>, targetX: Int) -> Int? {
        var bestX: Int?
        var bestScore = 0.0

        for x in xRange where x > 1 && x < frame.width - 2 {
            let left = Double(frame.valueAt(x: x - 1, y: row))
            let center = Double(frame.valueAt(x: x, y: row))
            let right = Double(frame.valueAt(x: x + 1, y: row))
            let gradient = abs(right - left)
            let brightnessBoost = max(0.0, center - 95.0) * 0.4
            let proximityPenalty = Double(abs(x - targetX)) * 0.15
            let score = gradient + brightnessBoost - proximityPenalty

            if score > bestScore {
                bestScore = score
                bestX = x
            }
        }

        guard bestScore > 18 else { return nil }
        return bestX
    }

    private func fitLaneLine(points: [CGPoint], isLeft: Bool) -> LaneLine? {
        guard points.count >= 5 else { return nil }

        let ys = points.map(\.y)
        let xs = points.map(\.x)
        let yMean = ys.reduce(CGFloat.zero, +) / CGFloat(ys.count)
        let xMean = xs.reduce(CGFloat.zero, +) / CGFloat(xs.count)

        var numerator: CGFloat = 0
        var denominator: CGFloat = 0

        for point in points {
            let dy = point.y - yMean
            numerator += dy * (point.x - xMean)
            denominator += dy * dy
        }

        guard denominator > 0.0001 else { return nil }

        let slope = numerator / denominator
        let intercept = xMean - (slope * yMean)
        let yTop: CGFloat = 0.58
        let yBottom: CGFloat = 0.98
        let xTop = slope * yTop + intercept
        let xBottom = slope * yBottom + intercept
        let confidence = min(0.92, 0.45 + (Double(points.count) / 20.0))

        guard xTop.isFinite, xBottom.isFinite else { return nil }
        guard isLeft ? xBottom < 0.55 : xBottom > 0.45 else { return nil }

        return LaneLine(
            startPoint: CGPoint(x: xTop.clamped(to: CGFloat.zero...1), y: yTop),
            endPoint: CGPoint(x: xBottom.clamped(to: CGFloat.zero...1), y: yBottom),
            confidence: confidence
        )
    }

    private func detectVehicleCandidates(in frame: DownsampledFrame) -> [CGRect] {
        guard let previousFrame else { return [] }

        let startY = Int(Double(frame.height) * 0.28)
        let endY = Int(Double(frame.height) * 0.9)
        let startX = Int(Double(frame.width) * 0.12)
        let endX = Int(Double(frame.width) * 0.88)

        var active = Array(repeating: false, count: frame.width * frame.height)
        for y in startY..<endY {
            for x in startX..<endX {
                let diff = abs(Int(frame.valueAt(x: x, y: y)) - Int(previousFrame.valueAt(x: x, y: y)))
                if diff > 24 {
                    active[(y * frame.width) + x] = true
                }
            }
        }

        var visited = Array(repeating: false, count: frame.width * frame.height)
        var boxes: [CGRect] = []

        for y in startY..<endY {
            for x in startX..<endX {
                let index = (y * frame.width) + x
                guard active[index], visited[index] == false else { continue }

                var queue = [(x: Int, y: Int)]()
                queue.append((x, y))
                visited[index] = true

                var minX = x
                var maxX = x
                var minY = y
                var maxY = y
                var count = 0

                while queue.isEmpty == false {
                    let current = queue.removeLast()
                    count += 1
                    minX = min(minX, current.x)
                    maxX = max(maxX, current.x)
                    minY = min(minY, current.y)
                    maxY = max(maxY, current.y)

                    for neighbor in neighbors(of: current, width: frame.width, height: frame.height) {
                        let neighborIndex = (neighbor.y * frame.width) + neighbor.x
                        guard active[neighborIndex], visited[neighborIndex] == false else { continue }
                        visited[neighborIndex] = true
                        queue.append(neighbor)
                    }
                }

                let boxWidth = maxX - minX + 1
                let boxHeight = maxY - minY + 1
                let aspectRatio = CGFloat(boxWidth) / CGFloat(max(boxHeight, 1))

                guard count >= 18 else { continue }
                guard aspectRatio > 0.6 && aspectRatio < 3.6 else { continue }

                let normalizedBox = CGRect(
                    x: CGFloat(minX) / CGFloat(frame.width),
                    y: CGFloat(minY) / CGFloat(frame.height),
                    width: CGFloat(boxWidth) / CGFloat(frame.width),
                    height: CGFloat(boxHeight) / CGFloat(frame.height)
                )

                if normalizedBox.height > 0.06, normalizedBox.width > 0.05 {
                    boxes.append(normalizedBox)
                }
            }
        }

        return boxes
    }

    private func neighbors(of point: (x: Int, y: Int), width: Int, height: Int) -> [(x: Int, y: Int)] {
        [(-1, 0), (1, 0), (0, -1), (0, 1)].compactMap { offset in
            let dx = offset.0
            let dy = offset.1
            let nextX = point.x + dx
            let nextY = point.y + dy
            guard nextX >= 0, nextY >= 0, nextX < width, nextY < height else { return nil }
            return (nextX, nextY)
        }
    }

    private func inferEvent(
        from trackedVehicles: [TrackedVehicle],
        lanes: [LaneLine],
        timestamp: Date,
        sensitivity: Double
    ) -> SuspectedEvent? {
        guard trackedVehicles.isEmpty == false else { return nil }

        let sortedLanes = lanes.sorted(by: { $0.endPoint.x < $1.endPoint.x })
        for vehicle in trackedVehicles {
            let vehicleCenterX = vehicle.boundingBox.midX
            let laneCenterX: CGFloat

            if sortedLanes.count >= 2 {
                let leftLaneX = xPosition(of: sortedLanes[0], at: vehicle.boundingBox.maxY)
                let rightLaneX = xPosition(of: sortedLanes[1], at: vehicle.boundingBox.maxY)
                laneCenterX = (leftLaneX + rightLaneX) / 2

                let overlapsBoundary = vehicle.boundingBox.minX < rightLaneX && vehicle.boundingBox.maxX > rightLaneX
                if overlapsBoundary && abs(vehicle.horizontalVelocity) > (0.008 - CGFloat(sensitivity * 0.003)) {
                    return SuspectedEvent(
                        type: .solidLineLaneChange,
                        timestamp: timestamp,
                        confidence: min(0.89, vehicle.confidence + 0.12),
                        summary: "Vehicle candidate overlapped a detected lane boundary with lateral motion."
                    )
                }
            } else {
                laneCenterX = 0.5
            }

            let previousSide = previousVehicleSides[vehicle.id] ?? (vehicleCenterX - laneCenterX)
            let currentSide = vehicleCenterX - laneCenterX
            previousVehicleSides[vehicle.id] = currentSide

            let crossingThreshold = CGFloat(0.025 - (sensitivity * 0.01))
            let crossedCenter = previousSide.sign != currentSide.sign
                && abs(previousSide) > crossingThreshold
                && abs(currentSide) > crossingThreshold

            if crossedCenter && abs(vehicle.horizontalVelocity) > 0.01 {
                return SuspectedEvent(
                    type: .centerLineCrossing,
                    timestamp: timestamp,
                    confidence: min(0.87, vehicle.confidence + 0.1),
                    summary: "Tracked vehicle crossed the inferred lane center with measurable lateral motion."
                )
            }
        }

        return nil
    }

    private func xPosition(of lane: LaneLine, at normalizedY: CGFloat) -> CGFloat {
        let dy = lane.endPoint.y - lane.startPoint.y
        guard abs(dy) > 0.0001 else { return lane.endPoint.x }
        let t = ((normalizedY - lane.startPoint.y) / dy).clamped(to: CGFloat.zero...1)
        return lane.startPoint.x + ((lane.endPoint.x - lane.startPoint.x) * t)
    }
}

private struct DownsampledFrame {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    func valueAt(x: Int, y: Int) -> UInt8 {
        pixels[(y * width) + x]
    }

    static func make(from sampleBuffer: CMSampleBuffer, width: Int, height: Int) -> DownsampledFrame? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        }

        let sourceWidth = CVPixelBufferGetWidth(imageBuffer)
        let sourceHeight = CVPixelBufferGetHeight(imageBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var pixels = Array(repeating: UInt8(0), count: width * height)
        for targetY in 0..<height {
            let sourceY = min(sourceHeight - 1, (targetY * sourceHeight) / height)
            for targetX in 0..<width {
                let sourceX = min(sourceWidth - 1, (targetX * sourceWidth) / width)
                let offset = (sourceY * bytesPerRow) + (sourceX * 4)
                let blue = Double(buffer[offset])
                let green = Double(buffer[offset + 1])
                let red = Double(buffer[offset + 2])
                let grayscale = UInt8(max(0, min(255, Int((0.114 * blue) + (0.587 * green) + (0.299 * red)))))
                pixels[(targetY * width) + targetX] = grayscale
            }
        }

        return DownsampledFrame(width: width, height: height, pixels: pixels)
    }
}

private struct VehicleTrack {
    let id: Int
    let boundingBox: CGRect
    let lastUpdate: Date
    let horizontalVelocity: CGFloat
}

private struct VehicleTracker {
    private var nextID = 1
    private var tracks: [VehicleTrack] = []

    mutating func update(candidates: [CGRect], timestamp: Date) -> [TrackedVehicle] {
        var updatedTracks: [VehicleTrack] = []
        var unmatchedTracks = tracks

        for candidate in candidates.sorted(by: { $0.width * $0.height > $1.width * $1.height }) {
            let bestMatch = unmatchedTracks.enumerated().max { lhs, rhs in
                intersectionOverUnion(candidate, lhs.element.boundingBox) < intersectionOverUnion(candidate, rhs.element.boundingBox)
            }

            if let bestMatch, intersectionOverUnion(candidate, bestMatch.element.boundingBox) > 0.18 {
                let previousCenter = bestMatch.element.boundingBox.midX
                let currentCenter = candidate.midX
                let deltaTime = max(0.016, timestamp.timeIntervalSince(bestMatch.element.lastUpdate))
                let velocity = (currentCenter - previousCenter) / CGFloat(deltaTime)

                updatedTracks.append(
                    VehicleTrack(
                        id: bestMatch.element.id,
                        boundingBox: candidate,
                        lastUpdate: timestamp,
                        horizontalVelocity: velocity
                    )
                )
                unmatchedTracks.remove(at: bestMatch.offset)
            } else {
                updatedTracks.append(
                    VehicleTrack(
                        id: nextID,
                        boundingBox: candidate,
                        lastUpdate: timestamp,
                        horizontalVelocity: 0
                    )
                )
                nextID += 1
            }
        }

        tracks = updatedTracks.filter { timestamp.timeIntervalSince($0.lastUpdate) < 1.0 }

        return tracks.map { track in
            TrackedVehicle(
                id: track.id,
                boundingBox: track.boundingBox,
                confidence: min(0.9, 0.45 + Double(track.boundingBox.width * track.boundingBox.height * 3.0)),
                horizontalVelocity: track.horizontalVelocity
            )
        }
    }

    private func intersectionOverUnion(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard intersection.isNull == false else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = (lhs.width * lhs.height) + (rhs.width * rhs.height) - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

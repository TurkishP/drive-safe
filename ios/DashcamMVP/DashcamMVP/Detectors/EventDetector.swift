import AVFoundation
import CoreGraphics
import Foundation

struct LaneLine: Identifiable {
    let id = UUID()
    let startPoint: CGPoint
    let endPoint: CGPoint
    let confidence: Double
}

struct TrackedVehicle: Identifiable {
    let id: Int
    let boundingBox: CGRect
    let confidence: Double
    let horizontalVelocity: CGFloat
}

struct PerceptionSnapshot {
    let timestamp: Date
    let frameSize: CGSize
    let lanes: [LaneLine]
    let trackedVehicles: [TrackedVehicle]
    let debugSummary: String
}

protocol EventDetector: AnyObject {
    var onPerceptionUpdate: ((PerceptionSnapshot) -> Void)? { get set }
    func process(sampleBuffer: CMSampleBuffer, timestamp: Date, sensitivity: Double) -> SuspectedEvent?
    func makeManualEvent(timestamp: Date) -> SuspectedEvent
    func reset()
}

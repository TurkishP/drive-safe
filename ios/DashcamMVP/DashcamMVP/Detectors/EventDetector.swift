import AVFoundation
import Foundation

protocol EventDetector: AnyObject {
    func process(sampleBuffer: CMSampleBuffer, timestamp: Date, sensitivity: Double) -> SuspectedEvent?
    func makeManualEvent(timestamp: Date) -> SuspectedEvent
    func reset()
}
